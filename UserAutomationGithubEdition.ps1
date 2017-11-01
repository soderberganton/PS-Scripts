
#Plockar fram datum och skapar användarnamnssuffix
$Month = get-date | select -ExpandProperty Month
$Year = (Get-Date | Select-Object -ExpandProperty Year).ToString().Substring(2)
If (($Month -lt 6) -or ($Month -eq 12)) {
  $UserSuf = ('VK' + $Year)
}
    else {
      $UserSuf = ('HK' + $Year)
  }

#Hämtar in användardata från databasen
$Users = Invoke-Sqlcmd -Query "SELECT * FROM -Database- # " -ServerInstance "localhost\SQLExpress"

#Skapar användarnamnet utifrån förnamn och efternamn samt kör en kontroll mot AD för att kolla att det inte blir några dubbletter.
Foreach ($User in $Users) {
	$PreUserName=(($User.lastname).substring(0,2)+($User.firstname).substring(0,2)).ToLower() -replace "ä","a" -replace "å","a" -replace "ö","o"
	$Progress = 1
	$inc = 1

	While ($Progress -eq 1) {
		$Match = Get-ADUser -Filter {sAMAccountName -eq $PreUserName}
	If ($Match -ne $Null) {
		$PreUserName = (($User.lastname).substring(0,2+$inc++)+($User.firstname).substring(0,2)).ToLower() -replace "ä","a" -replace "å","a" -replace "ö","o"
	}
		Else {
			$UserName = $PreUserName
			$Progress = 2}

#Framställer fram attributen från tidigare funktioner samt databasen.
	$sAMAccountName = ($UserName + $UserSuf).ToLower() -replace " ",""
	$UPN = $sAMAccountName + #'@companyname.domain'
	$Description = $UserSuf
	$Title = #'title'
	$DisplayName = $User.firstname+" "+$User.lastname
	$PNR = $User.pnr
	$UID = $User.uid
	$Name = $DisplayName
	$MailAddress = $User.email
	$password = <#"SomePassword"#> | ConvertTo-SecureString -AsPlainText -Force
	#$mobile = $User.mobile
	$OptionalGroup = #"OU=container,DC=<somecompany>,DC=domain"
	$OU = #"OU=container,DC=<somecompany>,DC=com"


#Skapar användaren med de givna attributen
	New-ADUser -Name $Name `
		-SamAccountName $sAMAccountName `
	  -GivenName $User.firstname `
		-Surname $User.lastname `
		-DisplayName $DisplayName `
		-Description $Description `
		-AccountPassword $password `
		-EmailAddress $User.email `
		-Path $OU `
		-UserPrincipalName $UPN `
		-Title $Title `
		-Company $UserSuf `
		-PasswordNeverExpires $True `
		-CannotChangePassword $False `
		-employeeNumber $PNR `
		-OtherAttributes @{'uid'=$UID} `

#Lägger till access till eduroam
		Add-ADGroupMember $OptionalGroup -Members $sAMAccountName

}
}
