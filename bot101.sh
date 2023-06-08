#!/bin/bash

# Download URL for the Go binary archive (change as needed)
GO_DOWNLOAD_URL="https://golang.org/dl/go1.16.4.linux-amd64.tar.gz"

# Destination directory where Go will be installed
GO_INSTALL_DIR="/usr/local"

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Go is installed
if ! command_exists go; then
    echo "Go is not installed. Installing Go..."
    # Download the Go binary archive
    echo "Downloading Go..."
    wget -P /tmp "$GO_DOWNLOAD_URL"

    # Extract the archive
    echo "Extracting archive..."
    tar -C "$GO_INSTALL_DIR" -xzf /tmp/go*.tar.gz

    # Add Go binaries to the system's PATH
    echo "Configuring environment variables..."
    echo "export PATH=\$PATH:$GO_INSTALL_DIR/go/bin" >> ~/.bashrc
    source ~/.bashrc

    # Cleanup
    echo "Cleaning up..."
    rm /tmp/go*.tar.gz

    echo "Go installation completed!"
else
    echo "Go is already installed."
fi

# Check if Python 3 and pip3 are installed
if ! command_exists python3 || ! command_exists pip3; then
    echo "Python 3 and/or pip3 are not installed. Installing Python 3 and pip3..."
    sudo apt update
    sudo apt install -y python3 python3-pip
    echo "Python 3 and pip3 installation completed!"
else
    echo "Python 3 and pip3 are already installed."
fi

# Function to check if Dirsearch is installed
check_dirsearch() {
    if ! command_exists dirsearch; then
        echo "Dirsearch is not installed. Installing Dirsearch..."
        git clone https://github.com/maurosoria/dirsearch.git
        echo "Dirsearch installation completed!"
    else
        echo "Dirsearch is already installed."
    fi
}
# Function to check if Nmap is installed
check_nmap() {
    if ! command_exists nmap; then
        echo "Nmap is not installed. Installing Nmap..."
        sudo apt update
        sudo apt install -y nmap
        echo "Nmap installation completed!"
    else
        echo "Nmap is already installed."
    fi
}
# Function to check if Nuclei is installed
check_nuclei() {
    if ! command_exists nuclei; then
        echo "Nuclei is not installed. Installing Nuclei..."
        GO111MODULE=on go get -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei
        echo "Nuclei installation completed!"
    else
        echo "Nuclei is already installed."
    fi
}
# Function to check if WaybackURL is installed
check_waybackurl() {
    if ! command_exists waybackurls; then
        echo "WaybackURL is not installed. Installing WaybackURL..."
        go get github.com/tomnomnom/waybackurls
        echo "WaybackURL installation completed!"
    else
        echo "WaybackURL is already installed."
    fi
}
# Check if Subfinder is installed
if ! command_exists subfinder; then
    echo "Subfinder is not installed. Installing Subfinder..."
    GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
    echo "Subfinder installation completed!"
else
    echo "Subfinder is already installed."
fi

# Check if HTTPX is installed
if ! command_exists httpx; then
    echo "HTTPX is not installed. Installing HTTPX..."
    GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx
    echo "HTTPX installation completed!"
else
    echo "HTTPX is already installed."
fi
# Check if Hakrawler is installed
if ! command_exists hakrawler; then
    echo "Hakrawler is not installed. Installing Hakrawler..."
    GO111MODULE=on go get -v github.com/hakluke/hakrawler
    echo "Hakrawler installation completed!"
else
    echo "Hakrawler is already installed."
fi
# Check if Aquatone is installed
if ! command_exists aquatone; then
    echo "Aquatone is not installed. Installing Aquatone..."
    go get -v github.com/michenriksen/aquatone
    echo "Aquatone installation completed!"
else
    echo "Aquatone is already installed."
fi

# Check if Nuclei is installed
check_nuclei

# Check if Dirsearch is installed
check_dirsearch

# Check if Nmap is installed
check_nmap

# Check if WaybackURL is installed
check_waybackurl

# Check if Dirsearch is installed and run it on HTTPX results
check_dirsearch

# Check if Nmap is installed and run it to check the 1000 most common open ports for each domain
check_nmap

# Check if WaybackURL is installed and run it on the subdomains results
check_waybackurl

# Check if Nuclei is installed and run it on HTTPX results
check_nuclei
# Function to check if a directory exists, create it if not, and navigate to it
ifexists() {
    if [ -d "$1" ]; then
        cd "$1" || exit
    else
        mkdir "$1"
        cd "$1" || exit
    fi
}

# Function to sort a file and remove duplicates
sortme() {
    x=$(date +"%I%M%S")
    cat "$1" | sort -u | tee "$x"
    mv "$x" "$1"
}

# Function to perform subdomain enumeration
sub-domain() {
    ifexists "$1"
    subfinder -d "$1" -silent | tee -a subfinder.txt
    cat *.txt | sort -u | tee subdomainlist.txt
    cat subdomainlist.txt | tee -a "$sub/allsubdomains.txt"
    cd "$sub" || exit
    sortme allsubdomains.txt
    echo "$1" | tee -a "$sub/alldomains.txt"
    sortme alldomains.txt
}

# Function to perform HTTPX scanning and capture screenshots with Aquatone
Httpx() {
    cat "$sub/allsubdomains.txt" | httpx -silent | tee -a livedomains.txt
    sortme livedomains.txt
    cat "$sub/allsubdomains.txt" | httpx -l domains --silent -tech-detect -title -status-code -web-server -ip -follow-host-redirects -cname -content-length -no-color | tee -a httpx_history.txt
    sortme httpx_history.txt

    echo "Capturing screenshots with Aquatone..."
    mkdir -p screenshots
    cat livedomains.txt | aquatone -out screenshots

    echo "Screenshots captured with Aquatone."
}
# Function to perform web scanning with Nuclei
Nuclei() {
    nuclei -l "$sub/livedomains.txt" -t /path/to/nuclei-templates -o nuclei_results.txt
    echo "Nuclei scanning completed. Results saved to nuclei_results.txt."
}

# Function to perform web crawling with Hakrawler
Hakrawler() {
    while read -r line; do echo "$line" | hakrawler -subs -d 5 -u -timeout 100 -insecure | tee -a hakrawler.txt; done < "$sub/livedomains.txt"
    sortme hakrawler.txt
}




# Perform subdomain enumeration
read -rp "Enter the path to the domain list file: " domain_list
sub=$(pwd)
while IFS= read -r domain; do
    sub-domain "$domain"
done < "$domain_list"

# Perform HTTPX scanning and Aquatone screenshot capture
Httpx

#NMAP
echo "Running Nmap to check open ports..."
if [ -f "$sub/livedomains.txt" ]; then
    while IFS= read -r domain; do
        echo "Running Nmap for domain: $domain"
        nmap -p 1-1000 "$domain"
    done < "$sub/livedomains.txt"
else
    echo "No livedomains.txt file found. Skipping Nmap."
fi

# Perform web crawling with Hakrawler
Hakrawler

#WAYBACK 
if [ -f "$sub/allsubdomains.txt" ]; then
    echo "Running WaybackURL on subdomains..."
    cat "$sub/allsubdomains.txt" | waybackurls | tee -a waybackurls.txt
    echo "WaybackURL completed. Results saved to waybackurls.txt."
else
    echo "No allsubdomains.txt file found. Skipping WaybackURL."
fi
#DIRSEARCH 

if [ -f "$sub/livedomains.txt" ]; then
    while IFS= read -r domain; do
        echo "Running Dirsearch for domain: $domain"
        mkdir -p "$sub/$domain"
        dirsearch -u "$domain" -w /path/to/wordlist.txt -e php,asp,aspx,jsp -t 50 -x 400,401,403,404,500 -r -o "$sub/$domain/dirsearch.txt"
        echo "Dirsearch completed for domain: $domain"
    done < "$sub/livedomains.txt"
else
    echo "No livedomains.txt file found. Skipping Dirsearch."
fi

#Nuclei
if [ -f "$sub/livedomains.txt" ]; then
    Nuclei
else
    echo "No livedomains.txt file found. Skipping Nuclei."
fi
