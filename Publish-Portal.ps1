# https://learn-powershell.net/2012/06/03/working-with-new-cmdletbinding-arguments-helpurisupportspaging-and-positionalbinding-in-powershell-v3/
#!!!!!!!!!!!!!!!!!!!!!!!!Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

function Publish-Portal{
# positional binding to false, so args would not be dependant on position, but on name
[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$Help,
    [switch]$Statistics,
    [string]$Destination,
    # the rest of args are file names, make an array from them
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Args #files
)

# print help
if ($Help){
Write-Output "USAGE:
Publish-Portal [-Statistics] [-Destination destination] [files.markdown[]] [-Help]"
Write-Output "------------------------------------------------------------------------------"
Write-Output "[-Statistics] for in-depth statistics of file
[-Destination destination] for publishing .html files on server
[files.markdown[]] to transform files to html, if not given, transforms all in that directory
[-Help] for help message"
exit 0
}


# no files given -> adding all .markdown from current directory
if ($Args.count -eq 0){
    $Files= (Get-ChildItem -Path "*.markdown")
    }

# transforming file names to objects
else{
    # creating an empty array
    $Files=@()
    $Args | ForEach-Object{
        if (Test-Path $_){ $Files+=(Get-Item $_) }

        # file does not exist
        else{
            Write-Output "File $_ does not exist!"
            exit 1
        }
    }
}


# always generating new site directory
if (Test-Path site/){
    # deleting all files there
    Remove-Item site/ -Recurse
} 
New-Item -Name site -ItemType "Directory" | out-null


# creating new index and sending new-item cmdlet output to NULL
New-Item -Name site/index.html  | out-null

Add-Content -Path site/index.html -Value("<h1 align=center>FILE INDEX</h1>")
Add-Content -Path site/index.html -Value("<table border=1px width=40% bgcolor=#D0E9F5 align=center>")

# tr = row, th = header, td = data
# adding column names
if ($Statistics){
    Add-Content -Path site/index.html -value("<tr><th>Name</th><th>Date</th><th>Url</th><th>Words count</th></tr>")
}
else{
    Add-Content -Path site/index.html -value("<tr><th>Name</th><th>Date</th><th>Url</th></tr>")
}
    
$FilesCount = 0
$WordsCount = 0
       
# proccessing all files in $Files
$Files | ForEach-Object {
    $FilesCount++

    $NewName=$_.BaseName

    # generating from pandoc
    pandoc $_.Name -f markdown -t html -s -o "site/$NewName.html"

    # adding new row
    Add-Content -Path site/index.html -Value("<tr>")
    # adding name of the file from header (line containing '#') + removing '#'
    Add-Content -Path site/index.html -Value("<td align=center>"+ (Get-Content $_ | Where-Object {$_ -match "# "}).Replace("#","") + "</td>") 
    # adding last write time
    Add-Content -Path site/index.html -Value  ("<td align=center>" + $_.LastWriteTime + "</td>") 
    # adding link to file
    Add-Content -Path site/index.html -Value  ("<td align=center>"+ "<a href=$NewName.html>$NewName</a>" + "</td>" ) 

    # adding statistics
    if ($Statistics){
            $Length= (Get-Content -Path $_ | Measure-Object -Word).Words
            # not counting '#'
            $Length--
            Add-Content -Path site/index.html -Value ("<td align=center>" + $Length + "</td>")
            $WordsCount+=$Length
    }
    Add-Content -Path site/index.html -Value("</tr>")
}
Add-Content -Path site/index.html -Value("</table>")

# adding new header with stats
if ($Statistics){
    Add-Content -Path site/index.html -Value ("<h3 align=center>FILES: " + "$FilesCount" + " TOTAL WORDS: " + "$WordsCount"+  "</h3>")     
}

# publishing site
if ($Destination){
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/copy-item?view=powershell-7.5

    # creates new folder Destination if it not exists and sends contents of ./site there
    $Session = New-PSSession -ComputerName "s.ics.upjs.sk" -Credential zora_slovinska
    Copy-Item  "./site" -Destination $Destination -ToSession $Session -Recurse
    Write-Output "sending to s.ics.upjs.sk to folder $Destination ..."
}






} 