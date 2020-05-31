# my-ytdl
bash-wrapper for youtube-dl; with support for parallelization of downloads
```
Use: download_from_youtube.sh [options]...
See also config file, which name should be ./download_from_youtube.conf
-m|--mode       should be ASK|BEST|WORST|BAUDIO it's about type|quality of content which'll be downloaded;
                Default: BEST; Case insensitive;
-u|--urls       Should be double-quoted string of whitespace separated url, one or more url;
-d|--dop        Degree of parallelism of download; That is: how many download should be run simultaneously;
                Maximum allowed value: 8; Default: 2;
-r|--retry      download_from_youtube.sh makes script-file with youtube-dl statements, for downloading video for you,
                by urls which you provide;
                In case youtube-dl download(s) hanged, while working, and you cancel it by ctrl-c or somehow,
                you can ask download_from_youtube.sh to retry to execute the script-file with help of -r|--retry options;
##############################################################################################################
About parameter in config-file:
SAVEDIR         Folder for files of downloaded contents;
LOG_FILE        Full-path of log file;
DEBUG           1: do debug output; Any other value - do not debug output;
URLS_LIST       File with url, one url in one line
BEST_PROFILE    Set of youtube-dl for download content with best quality of media, f.e.: "--no-progress --no-warnings -f best --restrict-filenames"
WORST_PROFILE   Set of youtube-dl for download content with best quality of media, f.e.: "--no-progress --no-warnings -f worst --restrict-filenames"
YOUTUBEDL       Full-path to the youtube-dl utility
SCRIPT          Full-path to file where youtube-dl statement(s) will be placed
LINES_LIMIT     Limit for amount of string-lines in log file;
DOP             Degree of parallelism of download; That is: how many download should be run simultaneously;
                Maximum allowed value: 8; Default: 2;

```
