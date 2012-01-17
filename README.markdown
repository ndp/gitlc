# Git Line Count

Command line utility to count lines of code contributed to a git repository.


## Usage

<pre>$ ./gitlc.rb -r git-workspace-directory</pre>

### Options
*  -A, --aliases file.yml           YAML file with aliases for authors
*  -c, --count c                    Number of versions to investigate
*  -s, --since c                    Show commits more recent than a specific date
*  -a, --author a                   Show commits by given author
*  -p, --people                     Show commit data by person
*  -d, --date                       Show commit data by date
*  -m, --month                      Show commit data by month
*  -l, --log                        Show commit data
*  -h, --help                       Display this screen


#### Alias file

An alias file may be provided to combine two different developers' line counts. This may be because
a single developer uses multiple accounts, has changed email throughout a project, or you want
to group users together for a metric.

The format of the file is:

<pre>---
andy:
- ndp
- andy.peterson
- a.peterson
- apeterson
steve:
- sjobs
- jobs</pre>

