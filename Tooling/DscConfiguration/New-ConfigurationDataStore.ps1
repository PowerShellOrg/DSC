function New-DscConfigurationDataStore {
	param (
		[parameter(mandatory)]
		$Path
	)
	$Path = (resolve-path $path).Path

	mkdir (join-path $Path 'AllNodes') | out-null
	mkdir (join-path $Path 'Credentials') | out-null
	mkdir (join-path $Path 'Services') | out-null
	mkdir (join-path $Path 'SiteData') | out-null
	mkdir (join-path $Path 'Applications') | out-null

	$script:ConfigurationDataPath = $Path
}
