#!/usr/bin/perl -w

use strict;
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Data::Dumper;
use Getopt::Long;
my $source_path = '';
my $output_dir = '~';
my $fade_secunds = 5;
my $time_multiplier = 10;
my $target_fps = 60;
GetOptions(
    "sourcepath=s" => \$source_path,
    "out=s"        => \$output_dir,
    "time-multiplier=i" => \$time_multiplier,
    "fade-secunds=i" => \$fade_secunds,
    "target-fps=i" => \$target_fps,
    "help"         => \&help
    ) or die('wrong commandline');
my $tmppath = sprintf('%s/trash', $source_path);
mkdir($tmppath);

my $cpu_count = get_cpu_count();

sub help
{
  print "TODO: help\n";
  exit (0);
}

sub echo_log
{
  my $str = $_[0];
  print sprintf("---------------------------------------------------------------\n%s\n---------------------------------------------------------------\n", $str);
}

sub get_cpu_count
{
  my $cpu_count = `cat /proc/cpuinfo | grep vendor_id | wc -l`;
  chomp $cpu_count;
  return int($cpu_count);
}

sub get_filelist
{
  my $dir = $_[0];
  print Dumper($dir);
  my $file;
  my @files;
  opendir (DIR, "$dir");
  while ($file = readdir(DIR))
  {
    if ($file =~ m/\.(mp4|avi|mpe?g)$/i)
    {
      push (@files, sprintf('%s/%s', $dir, $file));
    }
  }
  return sort {$a cmp $b} @files;
}

sub parse_duration
{
  my $s = $_[0];
  use integer;
  return sprintf("%02d:%02d:%02d", $s/3600, $s/60%60, $s%60);
}

sub get_video_length
{
  my $file = $_[0];
  echo_log(sprintf('Getting duration of %s', $file));
  my $cmd = sprintf('ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 %s', $file);
  my $len = `$cmd`;
  chomp $len;
  return int($len);
}

sub run_ffmpeg
{
  my $options = $_[0];
  my $cmd = sprintf('nice -n 20 ffmpeg -hide_banner -threads %s -y -hwaccel cuda -c:v h264_cuvid  %s', $cpu_count, $options);
  echo_log($cmd);
  system($cmd);
}

sub run_ffmpeg_encode
{
  my $source_file = $_[0];
  my $filters     = $_[1];
  my $result_file = $_[2];
  run_ffmpeg(sprintf('-i %s -filter_complex "%s;[tmp_video]fps=fps=%s,pp=al,hqdn3d[v]" -map "[v]" -map "[a]" -c:v h264_nvenc -preset lossless -profile:v high444p -2pass 1 %s',
                    $source_file,
                    $filters,
                    $target_fps,
                    $result_file));
}

sub fade_in
{
  my $file = $_[0];
  echo_log(sprintf('Fade in %s', $file));
  my $vid_length_s = get_video_length($file);
  run_ffmpeg(sprintf('-i %s -ss 00:00:00 -to %s -c copy %s/cut_in.mp4',
                    $file,
                    parse_duration($fade_secunds + 1),
                    $tmppath));
  run_ffmpeg(sprintf('-i %s -ss %s -to %s -c copy %s/cut_in_suffix.mp4',
                    $file,
                    parse_duration($fade_secunds + 1),
                    parse_duration($vid_length_s),
                    $tmppath));
  run_ffmpeg_encode(sprintf('%s/cut_in.mp4', $tmppath),
                    sprintf('[0:v]fade=t=in:st=0:d=%s[tmp_video];[0:a]afade=t=in:st=0:d=%s[a]', $fade_secunds, $fade_secunds),
                    sprintf('%s/fade_in.mp4', $tmppath));
  # run_ffmpeg(sprintf('-i %s/cut_in.mp4 -vf "fade=t=in:st=0:d=%s" -af "afade=t=in:st=0:d=%s" %s/fade_in.mp4',
  #                   $tmppath,
  #                   $fade_secunds, $fade_secunds,
  #                   $tmppath));
}

sub fade_out
{
  my $file = $_[0];
  echo_log(sprintf('Fade out %s', $file));
  my $vid_length_s = get_video_length($file);
  run_ffmpeg(sprintf('-i %s -ss %s -to %s -c copy %s/cut_out.mp4',
                    $file,
                    parse_duration($vid_length_s - $fade_secunds - 1),
                    parse_duration($vid_length_s),
                    $tmppath));
  run_ffmpeg(sprintf('-i %s -ss 00:00:00 -to %s -c copy %s/cut_out_prefix.mp4',
                    $file,
                    parse_duration($vid_length_s - $fade_secunds - 1),
                    $tmppath));
  run_ffmpeg_encode(sprintf('%s/cut_out.mp4', $tmppath),
                    sprintf('[0:v]fade=t=out:st=1:d=%s[tmp_video];[0:a]afade=t=out:st=1:d=%s[a]', $fade_secunds, $fade_secunds),
                    sprintf('%s/fade_out.mp4', $tmppath));
#   run_ffmpeg(sprintf('-i %s/cut_out.mp4 -vf "fade=t=out:st=1:d=%s" -af "afade=t=out:st=1:d=%s" %s/fade_out.mp4',
#                     $tmppath,
#                     $fade_secunds, $fade_secunds,
#                     $tmppath));
}

sub concat
{
  my @files = @{$_[0]};
  my $result_file = $_[1];
  echo_log(sprintf("Concatenating \n%s \nto %s", join("\n", @files), $result_file));
  my $concat_txt_file = sprintf('%s/concat_options.txt', $tmppath);
  my $concat_txt_file_fh;
  open($concat_txt_file_fh, '>', $concat_txt_file) or die $!;
  foreach my $file (@files)
  {
    print {$concat_txt_file_fh} sprintf("file '%s'\n", $file);
  }
  close($concat_txt_file_fh);
  run_ffmpeg(sprintf('-f concat -safe 0 -i %s -c:v copy -c:a copy %s',
                    $concat_txt_file,
                    $result_file));
  unlink($concat_txt_file);
}

sub speed_up
{
  my $source_file = $_[0];
  my $result_file = $_[1];
  echo_log(sprintf('Speed up %s to %s', $source_file, $result_file));
  my $v_multiplier = 1 / $time_multiplier;
  my $a_multiplier = $time_multiplier;
  run_ffmpeg_encode($source_file,
                    sprintf('[0:v]setpts=%s*PTS[tmp_video];[0:a]atempo=%s[a]',
                            $v_multiplier,
                            $a_multiplier),
                    $result_file)
}


my @video_files = get_filelist($source_path);

fade_in($video_files[0]);
fade_out($video_files[-1]);

my @concat_main_files = (sprintf('%s/cut_in_suffix.mp4', $tmppath), @video_files[1..scalar @video_files - 2], sprintf('%s/cut_out_prefix.mp4', $tmppath));
concat(\@concat_main_files, sprintf('%s/concat_main.mp4', $tmppath));

speed_up(sprintf('%s/concat_main.mp4', $tmppath), sprintf('%s/speed_up_main.mp4', $tmppath));

my @concat_result_files = (sprintf('%s/fade_in.mp4', $tmppath), sprintf('%s/speed_up_main.mp4', $tmppath), sprintf('%s/fade_out.mp4', $tmppath));
concat(\@concat_result_files, sprintf('%s/result.mp4', $tmppath));
