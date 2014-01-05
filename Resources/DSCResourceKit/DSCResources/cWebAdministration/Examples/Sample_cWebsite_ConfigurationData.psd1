# Hashtable to define the environmental data
@{
    # Node specific data
    AllNodes = @(

       # All the WebServer has following identical information 
       @{
            NodeName           = "*"
            WebsiteName        = "FourthCoffee"
            SourcePath         = "C:\BakeryWebsite\"
            DestinationPath    = "C:\inetpub\FourthCoffee"
            DefaultWebSitePath = "C:\inetpub\wwwroot"
       },

       @{
            NodeName           = "WebServer1.fourthcoffee.com"
            Role               = "Web"
        },

       @{
            NodeName           = "WebServer2.fourthcoffee.com"
            Role               = "Web"
        }
    );
} 