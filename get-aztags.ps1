 # Connect-AzAccount 
 Select-AzSubscription -SubscriptionId "###" 
    
 $rgs = Get-AzResourceGroup -Name "###"  
    
 foreach ($Tag in $rgs.Tags)
 {
     foreach ($Key in $Tag.Keys)
     {
            
         if ($key -eq "environment")
         {
             $Key 
             $Key.Length
             $Tag.Keys
         }
     }
 }
