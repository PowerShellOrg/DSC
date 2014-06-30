Configuration HostsFileExample {
    Node "SRV2-WS2012R2" {
        HostsFile HostsFileDemo {
            hostName = "testhost100"
            ipAddress = "10.10.10.100"
            Ensure = "Present"
        }
    }

    Node "SRV3-WS2012R2" {
        HostsFile HostsFileDemo {
            hostName = "testhost102"
            ipAddress = "10.10.10.102"
            Ensure = "Absent"
        }
    }

    Node "SRV1-WS2012R2" {
        HostsFile TestHost120 {
            hostName = "testhost120"
            ipAddress = "10.10.10.120"
            Ensure = "Absent"
        }

        HostsFile TestHost130 {
            hostName = "testhost130"
            ipAddress = "10.10.10.130"
            Ensure = "Present"
        }

    }
}

HostsFileExample

