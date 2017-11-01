
#Get current date and creats a usernamesuffix
$Month = get-date | select -ExpandProperty Month
$Year = (Get-Date | Select-Object -ExpandProperty Year).ToString().Substring(2)
If (($Month -lt 6) -or ($Month -eq 12)) {
  $UserSuf = ('VK' + $Year)
}
    else {
      $UserSuf = ('HK' + $Year)
  }

#Import user data from a defined database
$Users = Invoke-Sqlcmd -Query "SELECT * FROM -Database- # " -ServerInstance "localhost\SQLExpress"

#Creats a username for each user in database based on first and lastname
#Also check each usernames availability in ActiveDirectory

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

#Creates attrubutes from given data in DB and the funcitons above

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


#Creates users from input above
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

#Add users to a give defined group
		Add-ADGroupMember $OptionalGroup -Members $sAMAccountName

}
}
