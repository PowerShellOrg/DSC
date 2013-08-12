DSC-Contrib
===========

Desired State Configuration Modules to augment the initial offering in PowerShell V4

ToDo
=====
- [x] Initial upload
- [ ] Make New-MofFile handle more data types and complex data types
- [ ] Improve the DSC Module creation documentation
- [ ] Add samples of complete configurations
- [ ] Add samples of nested configurations
- [ ] MORE Modules!


Getting Started With DSC Modules
--------------------------------
  

NOTE: 

  

There are two sets of MOF (Managed Object Framework) files generated in this process.  Each provider module has a MOF file defining a class representing the parameters to the functions in provider module.  

  

The second type of MOF file is created by running the configuration, with one generated per target node.  This MOF file is the serialization of the configuration defined in MOF format.  It references the MOF classes defined in the provider modules’ schema files and contains the values supplied in the configuration associated to the appropriate parameters.

  

The general flow of Resource Processing in DSC (from Configuration MOF to Desired State)

When you run the configuration function, a MOF file for each node is generated.  This describes the state the machine should be in after processing the MOF file.  

  

For each resource defined, the DSC engine uses the classes defined in the MOF to marshal parameters to call the PowerShell DSC provider module.

  

The DSC engine calls Test-TargetResource with the parameters defined in the MOF file (as mapped in the schema MOF).  If Test-TargetResource returns $false, then Set-TargetResource is called with the same parameter set.

  

###Provider Modules

  

####Naming

The module name will be the resource name when configurations are defined.  The module will have to export three functions (you can have more, but it has to export these three specific functions).  You can specify an alias name for the module in the MOF schema (detailed below).  

  

####Module Metadata

The module must contain a PSD1 module metadata file (for versioning purposes).  That PSD1 can load and export the required functions from any valid source (separate PS1s, or a PSM1).

  

####Functions

  

- Set-TargetResource 
    - Set-TargetResource is called if Test-TargetResource (described in a bit) returns false.  Test-TargetResource is called with the same parameters as Set-TargetResource. 
    - This function implements the change requested.  You’ll need to support both the case of “Ensure = ‘Present’” and “Ensure = ‘Absent’”.  If this resource represents a multi-step process and that process needs to support “suspend/resume” or requires reboots, it may be an indication that you want to break it into several resources, otherwise you’ll have to implement the stage checking in this function.   
    - Each parameter for this function will need to be modeled in the CIM schema in a CIM class named for the resource type, so if you expect structured objects, you’ll need to define comprehensive schema documents. 
    - Logging for this function occurs in the form of verbose output (which is written to the DSC event log). 
    - While the DSC engine should only call this function if Test-TargetResource returns false, it would be prudent to write the system state changes in as idempotent a manner as possible. 

- Test-TargetResource 
    - Test-TargetResource validates whether a resource configuration is in the desired state. 
    - Test-TargetResource offers the same parameters as Set-TargetResource. 
    - Test-TargetResource evaluate the final state of the resource (not intermediate steps) and returns a $true if the configuration matches or $false if the configuration does not. 
    - This function needs to support both “Ensure = ‘Present’” and “Ensure = ‘Absent’” declarations. 

- Get-TargetResource 
    - This function inventories the resource based on the key values (mandatory parameters) for the CIM schema.   
    - Get-TargetResource returns a hashtable containing the values that match the current state of the resource configuration. 
    - Get-TargetResource only needs to support parameters that are noted as key values in the schema.mof file (mandatory parameters in the Set-TargetResource and Get-TargetResource functions). 

  

###The Schema

The final bit of creating a provider module is the MOF schema file.  The MOF schema file defines a CIM class used for serializing the parameter values from the configuration file and deserializing to apply as parameters to the call the above functions. 

Detailed documentation about MOF datatypes can be found here - [http://msdn.microsoft.com/en-us/library/cc250850.aspx](http://msdn.microsoft.com/en-us/library/cc250850.aspx)

  

####In creating the MOF schema file, there are a couple of rules.  

- All resource classes (those that represent the parameters for the Set-TargetResource) must inherit from MSFT_BaseResourceConfiguration.   
- The file is named {module}.schema.mof 
- Classes are attributed with a version number.   
    - I don’t know if that version has to match the module version number, but keeping those in sync would probably be a good practice. 

- Classes can be attributed with a “FriendlyName”, which would be the name that the resource would use in the configuration declaration.  The full class name is used in the generated configuration MOF. 
- Mandatory parameters are annotated as [Key] values. 
- Other parameters are annotated as [Write] values. 
    - If there is a ValidateSet or Enumeration, they are represented in a ValueMap and Values combination as part of the Write annotation. 

- The file encoding has to be Unicode or ASCII.  UTF8 will fail validation. 
  

Validation of the MOF file should be done by running:

mofcomp.exe -check {path to your mof file}.

  

####Example of a very basic schema.mof file:

````  
[version("1.0.0"), FriendlyName("PowerPlan")]

class PowerPlan : MSFT_BaseResourceConfiguration

{

[Key] string Name;

[write,ValueMap{"Present", "Absent"},Values{"Present", "Absent"}] string Ensure;

};
````