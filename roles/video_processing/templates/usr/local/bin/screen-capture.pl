#!/usr/bin/perl -w

use strict;
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use JSON;
use Time::HiRes qw (sleep);
use POSIX qw(strftime);
use Data::Dumper;
use Getopt::Long;
my $streaming = "capture";
my $youtube_stream_url = "rtmp://a.rtmp.youtube.com/live2";
my $stream_key = "";
my $twitch_server = "live-prg"; # http://bashtech.net/twitch/ingest.php
my $fps = 30;
my $window_title = '';
my $output_dir = '~';
GetOptions(
    "streaming=s" => \$streaming,
    "youtube-stream-url=s" => \$youtube_stream_url,
    "stream-key=s" => \$stream_key,
    "fps=i" => \$fps,
    "window=s" => \$window_title,
    "out=s" => \$output_dir,
    "help"     => \&help
    ) or die('wrong commandline');

sub help
{
  print "TODO: capture help\n";
  exit (0);
}

sub get_size_and_position
{
  my $cmd = sprintf('xdotool search --name "%s" getwindowgeometry | grep Position | awk \'{print $2}\'', $window_title);
  my @pos = split(/,/, `$cmd`);
  $cmd = sprintf('xdotool search --name "%s" getwindowgeometry | grep Geometry | awk \'{print $2}\'', $window_title);
  my @geo = split(/x/, `$cmd`);
  return { 'x' => $pos[0]+0, 'y' => $pos[1]+0, 'w' => $geo[0]+0, 'h' => $geo[1]+0 };
}

sub must_divide_by_2
{
    my $value = $_[0];
    if($value%2) { return $value + 1; }
    return $value;
}

sub run_ffmpeg_with_audio
{
  my $options = $_[0];
  my $window = get_size_and_position();
  my $pulse_source =  `pacmd list-sources | grep -e 'name:.*alsa_output' | sed -e 's/.*<\\(.*\\)>.*/\\1/ig' | head -n1`;
  chomp $pulse_source;
  #print  $pulse_source; exit(0);
  system(sprintf('ffmpeg -video_size %dx%d -framerate %d -f x11grab -i :0.0+%d,%d -f pulse -i "%s" '.
                 '-c:v libx264 -pix_fmt yuv420p -crf 0 -preset ultrafast -tune zerolatency -r %d -g %d -b:v 512k '.
                 '-c:a libmp3lame -ar 48000 -ac 2 -b:a 128k -q:v 3 -bufsize 512k %s',
                must_divide_by_2($window->{'w'}),
                must_divide_by_2($window->{'h'}),
                $fps*2,
                $window->{'x'},
                $window->{'y'},
                $pulse_source,
                $fps,
                $fps*2,
                $options));
}

sub run_ffmpeg
{
  my $options = $_[0];
  my $window = get_size_and_position();
  system(sprintf('ffmpeg -video_size %dx%d -framerate %d -f x11grab -i :0.0+%d,%d -an '.
                 '-c:v libx264 -pix_fmt yuv420p -crf 0 -preset ultrafast -tune zerolatency -r %d -g %d -b:v 512k '.
                 '-qscale:v 3 -bufsize 512k %s',
                must_divide_by_2($window->{'w'}),
                must_divide_by_2($window->{'h'}),
                $fps,
                $window->{'x'},
                $window->{'y'},
                $fps,
                $fps*2,
                $options));
}

sub capture_screen
{
  run_ffmpeg(sprintf('%s/%s_capture.mp4',
                $output_dir,
                strftime("%d.%m.%Y_%H-%M-%S", localtime)));
}

sub stream_youtube
{
  run_ffmpeg(sprintf('-f flv "%s/%s"',
                $youtube_stream_url,
                $stream_key));
}

sub stream_twitch
{
  run_ffmpeg(sprintf('-f flv "rtmp://%s.twitch.tv/app/%s"',
                $twitch_server,
                $stream_key));
}

for ($streaming)
{
  if   (/capture/) { capture_screen(); }
  elsif(/youtube/) { stream_youtube(); }
  elsif(/twitch/)  { stream_twitch();  }
  else { help(); }
}
