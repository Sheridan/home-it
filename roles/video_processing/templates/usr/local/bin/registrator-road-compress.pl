#!/usr/bin/perl -w

use strict;
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Data::Dumper;
use Getopt::Long;
my $source_path = '';
my $scale_to = 'none';
my $output_file = '~/result.mp4';
my $fade_secunds = 5;
my $cut_front_secunds = 0;
my $cut_back_secunds = 0;
my $time_multiplier = 10;
my $target_fps = 60;
GetOptions(
    "sourcepath=s"      => \$source_path,
    "out=s"             => \$output_file,
    "scale=s"           => \$scale_to,
    "time-multiplier=i" => \$time_multiplier,
    "fade-secunds=i"    => \$fade_secunds,
    "cut-front=i"       => \$cut_front_secunds,
    "cut-back=i"        => \$cut_back_secunds,
    "target-fps=i"      => \$target_fps,
    "help"              => \&help
    ) or die('wrong commandline');
my $tmppath = sprintf('%s/trash', $source_path);
mkdir($tmppath);

my $scale_template = ',scale=%s:-1:flags=lanczos+full_chroma_inp';
my $scale_bitrate_step = 32;
my $cpu_count = get_cpu_count();

sub help
{
  print <<_;
  registrator-road-compress.pl --sourcepath=/path/to/folder --out=/path/to/result.mp4
  Options:
    --sourcepath     : Path to a folder containing the source files (mp4, avi, mpg)
    --out            : Path to result file (will be created)
    --time-multiplier: Time multiplier of video (speedup), integer [2-100]
    --fade-secunds   : secunds of fide in at beginning of video and fade out at end
    --cut-front      : cut some secunds from beginning of video
    --cut-back       : cut some secunds from ending of video
    --target-fps     : FPS of resulting video
    --scale          : Scale. Values: none,1080,2k,4k; default: none
_
  exit (0);
}

sub echo_log
{
  my $str = $_[0];
  print sprintf("---------------------------------------------------------------\n%s\n---------------------------------------------------------------\n", $str);
}

sub get_cmd_output
{
  my $cmd = $_[0];
  echo_log(sprintf('Executing "%s"', $cmd));
  my $result = `$cmd`;
  chomp  $result;
  return $result;
}

sub get_cpu_count
{
  return int(get_cmd_output('cat /proc/cpuinfo | grep vendor_id | wc -l'));
}

sub get_filelist
{
  my $dir = $_[0];
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
  return int(get_cmd_output(sprintf('ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 %s', $file)));
}

sub run_ffmpeg
{
  my $options = $_[0];
  my $cmd = sprintf('nice -n 20 ffmpeg -hide_banner -threads %s -y -hwaccel cuda -c:v h264_cuvid  %s', $cpu_count, $options);
  echo_log(sprintf('Executing "%s"', $cmd));
  system($cmd);
}


sub run_ffmpeg_encode
{
  my $source_file = $_[0];
  my $filters     = $_[1];
  my $result_file = $_[2];
  my $scale_filter = '';
  my $scale_bitrate_mult = 1;
     if($scale_to eq '1080') { $scale_filter = sprintf($scale_template, 1920); $scale_bitrate_mult = 1; }
  elsif($scale_to eq '2k'  ) { $scale_filter = sprintf($scale_template, 2560); $scale_bitrate_mult = 2; }
  elsif($scale_to eq '4k'  ) { $scale_filter = sprintf($scale_template, 3840); $scale_bitrate_mult = 4; }
  run_ffmpeg(sprintf('-i %s -filter_complex "%s;[tmp_video]fps=fps=%s%s,pp=al,hqdn3d[v]" -map "[v]" -map "[a]" -c:v h264_nvenc -preset:v hq -rc-lookahead %s -surfaces 64 -b:v %sM -bf 3 %s',
                    $source_file,
                    $filters,
                    $target_fps,
                    $scale_filter,
                    $target_fps,
                    $scale_bitrate_mult * $scale_bitrate_step,
                    $result_file));

}

sub cut_front
{
  my $file = $_[0];
  echo_log(sprintf('Cut front %s', $file));
  my $vid_length_s = get_video_length($file);
  if( $vid_length_s <= $cut_front_secunds ) { die(sprintf('Too long front cut: %s <= %s', $vid_length_s, $cut_front_secunds)); }
  run_ffmpeg(sprintf('-i %s -ss %s -to %s -c copy %s/cut_front.mp4',
                  $file,
                  parse_duration($cut_front_secunds),
                  parse_duration($vid_length_s),
                  $tmppath));
}

sub cut_back
{
  my $file = $_[0];
  echo_log(sprintf('Cut back %s', $file));
  my $vid_length_s = get_video_length($file);
  if( $vid_length_s <= $cut_back_secunds ) { die(sprintf('Too long back cut: %s <= %s', $vid_length_s, $cut_back_secunds)); }
  run_ffmpeg(sprintf('-i %s -ss 00:00:00 -to %s -c copy %s/cut_back.mp4',
                    $file,
                    parse_duration($vid_length_s - $cut_back_secunds),
                    $tmppath));
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
}

sub concat
{
  my @files       = @{$_[0]};
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

sub cleanup
{
  for my $file (sprintf('%s/cut_in_suffix.mp4',  $tmppath),
                sprintf('%s/cut_out_prefix.mp4', $tmppath),
                sprintf('%s/cut_front.mp4',      $tmppath),
                sprintf('%s/cut_back.mp4',       $tmppath),
                sprintf('%s/cut_in.mp4',         $tmppath),
                sprintf('%s/cut_out.mp4',        $tmppath),
                sprintf('%s/fade_in.mp4',        $tmppath),
                sprintf('%s/fade_out.mp4',       $tmppath),
                sprintf('%s/concat_main.mp4',    $tmppath),
                sprintf('%s/speed_up_main.mp4',  $tmppath))
  {
    unlink($file);
  }
  rmdir($tmppath);
}

sub main
{

  my @video_files = get_filelist($source_path);
  if($cut_front_secunds > 0)
  {
    cut_front($video_files[0]);
    $video_files[0] = sprintf('%s/cut_front.mp4',  $tmppath);
  }

  if($cut_back_secunds > 0)
  {
    cut_back($video_files[-1]);
    $video_files[-1] = sprintf('%s/cut_back.mp4',  $tmppath);
  }

  fade_in($video_files[0]);   $video_files[0]  = sprintf('%s/cut_in_suffix.mp4',  $tmppath);
  fade_out($video_files[-1]); $video_files[-1] = sprintf('%s/cut_out_prefix.mp4',  $tmppath);

  concat(\@video_files, sprintf('%s/concat_main.mp4', $tmppath));

  speed_up(sprintf('%s/concat_main.mp4', $tmppath), sprintf('%s/speed_up_main.mp4', $tmppath));

  my @concat_result_files = (sprintf('%s/fade_in.mp4', $tmppath), sprintf('%s/speed_up_main.mp4', $tmppath), sprintf('%s/fade_out.mp4', $tmppath));
  concat(\@concat_result_files, $output_file);

  cleanup();
}

main();
