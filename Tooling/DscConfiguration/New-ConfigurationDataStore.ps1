function New-ConfigurationDataStore {
	param (
		[parameter(mandatory)]
		$Path
	)
	$Path = (resolve-path $path).Path

	mkdir (join-path $Path 'AllNodes') | out-null
	mkdir (join-path $Path 'Credentials') | out-null
	mkdir (join-path $Path 'Services') | out-null
	mkdir (join-path $Path 'SiteData') | out-null

	$script:ConfigurationDataPath = $Path
}
