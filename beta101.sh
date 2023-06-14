#!/bin/bash
ifexists()
{
    if [ -d "$1" ]
    then
        cd $1
    else
        mkdir $1
        cd $1
        mkdir nmap
    fi
}
sortme()
{
    x=$(date +"%I%M%S")
    cat $1 | sort -u | tee $x
    mv $x $1
}
subdomain()
{
    ifexists $1
    subfinder -d $1 -silent | tee -a subfinder.txt
    cat *.txt | sort -u | tee subdomainlist.txt
    while read line; do nmap -p 1-1000 $line -oA nmap/$line  ;done < $sub/livedomains.txt
    cat subdomainlist.txt | tee -a $sub/allsubdomains.txt
    cd $sub
    sortme allsubdomains.txt
    echo $1 | tee -a $sub/alldomains.txt
    sortme alldomains.txt
}
Httpx()
{
    cat $sub/allsubdomains.txt | httpx -silent | tee -a livedomains.txt
    sortme livedomains.txt
    cat $sub/allsubdomains.txt | httpx -l domains  --silent -tech-detect -title -status-code  -web-server -ip -follow-host-redirects -cname -content-length -no-color | tee -a httpx_history.txt
    sortme httpx_history.txt
    cat livedomains.txt | aquatone -out screenshots
}
Hakrawler()
{
    while read line; do echo $line| hakrawler -subs -d 5 -u -timeout 100 -insecure | tee -a hakrawler.txt; done < $sub/livedomains.txt
    sortme hakrawler.txt
    katana -list $sub/livedomains.txt | tee katana.txt
    sortme katana.txt
    cat "$sub/allsubdomains.txt" | waybackurls | tee -a waybackurls.txt
    while read line; do dirsearch -u "$line"  -e php,asp,aspx,jsp | tee dirsearch.txt ; done < $sub/livedomains.txt
    nuclei -l $sub/allsubdomains.txt -t ~/nuclei-templets
}
read dominlist
sub=$(pwd)
while read domain
do
subdomain $domain
done < $dominlist

Httpx
Hakrawler
