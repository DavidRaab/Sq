#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

# Sample JSON from Handbrake
my $content = qq<
{
    "Audio": {
        "AudioList": [
            {
                "Bitrate": 160,
                "CompressionLevel": -1.0,
                "DRC": 0.0,
                "DitherMethod": "auto",
                "Encoder": "av_aac",
                "Gain": 0.0,
                "Mixdown": "mono",
                "NormalizeMixLevel": false,
                "PresetEncoder": "av_aac",
                "Quality": -3.0,
                "Samplerate": 0,
                "Track": 0
            }
        ],
        "CopyMask": [
            "copy:aac"
        ],
        "FallbackEncoder": "av_aac"
    },
    "Destination": {
        "AlignAVStart": true,
        "ChapterList": [
            {
                "Duration": {
                    "Hours": 0,
                    "Minutes": 3,
                    "Seconds": 19,
                    "Ticks": 17925876
                },
                "Name": ""
            }
        ],
        "ChapterMarkers": false,
        "File": "/home/david/Pictures/Videos/VID_20241204_125407.m4v",
        "InlineParameterSets": false,
        "Mp4Options": {
            "IpodAtom": false,
            "Mp4Optimize": true
        },
        "Mux": "m4v"
    },
    "Filters": {
        "FilterList": [
            {
                "ID": 3,
                "Settings": {
                    "block-height": "16",
                    "block-thresh": "40",
                    "block-width": "16",
                    "filter-mode": "2",
                    "mode": "3",
                    "motion-thresh": "1",
                    "spatial-metric": "2",
                    "spatial-thresh": "1"
                }
            },
            {
                "ID": 4,
                "Settings": {
                    "mode": "7"
                }
            },
            {
                "ID": 7,
                "Settings": {
                    "mode": 2,
                    "rate": "27000000/900000"
                }
            },
            {
                "ID": 14,
                "Settings": {
                    "crop-bottom": 0,
                    "crop-left": 0,
                    "crop-right": 0,
                    "crop-top": 0,
                    "height": 1080,
                    "width": 1920
                }
            }
        ]
    },
    "Metadata": {
        "Name": "VID_20241204_125407"
    },
    "PAR": {
        "Den": 1,
        "Num": 1
    },
    "SequenceID": 0,
    "Source": {
        "Angle": 0,
        "Path": "/home/david/Pictures/Videos/VID_20241204_125407.mp4",
        "Range": {
            "End": 1,
            "Start": 1,
            "Type": "chapter"
        },
        "Title": 1
    },
    "Subtitle": {
        "Search": {
            "Burn": true,
            "Default": false,
            "Enable": false,
            "Forced": false
        },
        "SubtitleList": []
    },
    "Video": {
        "ChromaLocation": 1,
        "ColorInputFormat": 0,
        "ColorMatrix": 1,
        "ColorOutputFormat": 0,
        "ColorPrimaries": 1,
        "ColorRange": 1,
        "ColorTransfer": 1,
        "Encoder": "x264",
        "HardwareDecode": 0,
        "Level": "4.0",
        "Options": "",
        "Preset": "fast",
        "Profile": "main",
        "QSV": {
            "AdapterIndex": 0,
            "AsyncDepth": 0,
            "Decode": false
        },
        "Quality": 22.0,
        "Tune": "",
        "Turbo": false,
        "TwoPass": false
    }
}
>;

ok(1, 'Write a test');

done_testing;
