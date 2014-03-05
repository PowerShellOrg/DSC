Configuration AgentMG {
 
   Import-DscResource -ModuleName cSystemCenterManagement
   
   Node SCOMAG01 {

      SCOMAgentMG CheckMG {
         Ensure = ?Present?
         ManagementGroupName  = ?OM_Contoso?
         ManagementServerName = ?SCOM01.Contoso.com?
      }
 
   }


}


AgentMG -OutputPath .\AgentMG
Start-DscConfiguration -Path .\AgentMG -Wait -Force -Verbose -ErrorAction Continue

