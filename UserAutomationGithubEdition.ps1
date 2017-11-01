
#Plockar fram datum och skapar anv�ndarnamnssuffix
$Month = get-date | select -ExpandProperty Month
$Year = (Get-Date | Select-Object -ExpandProperty Year).ToString().Substring(2)
If (($Month -lt 6) -or ($Month -eq 12)) {
  $UserSuf = ('VK' + $Year)
}
    else {
      $UserSuf = ('HK' + $Year)
  }

#H�mtar in anv�ndardata fr�n databasen
$Users = Invoke-Sqlcmd -Query "SELECT * FROM -Database- # " -ServerInstance "localhost\SQLExpress"

#Skapar anv�ndarnamnet utifr�n f�rnamn och efternamn samt k�r en kontroll mot AD f�r att kolla att det inte blir n�gra dubbletter.
Foreach ($User in $Users) {
	$PreUserName=(($User.lastname).substring(0,2)+($User.firstname).substring(0,2)).ToLower() -replace "�","a" -replace "�","a" -replace "�","o"
	$Progress = 1
	$inc = 1

	While ($Progress -eq 1) {
		$Match = Get-ADUser -Filter {sAMAccountName -eq $PreUserName}
	If ($Match -ne $Null) {
		$PreUserName = (($User.lastname).substring(0,2+$inc++)+($User.firstname).substring(0,2)).ToLower() -replace "�","a" -replace "�","a" -replace "�","o"
	}
		Else {
			$UserName = $PreUserName
			$Progress = 2}

#Framst�ller fram attributen fr�n tidigare funktioner samt databasen.
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


#Skapar anv�ndaren med de givna attributen
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

#L�gger till access till eduroam
		Add-ADGroupMember $OptionalGroup -Members $sAMAccountName

}
}
