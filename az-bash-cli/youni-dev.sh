For setting up an Azure SQL Database for Youni's development environment, the following script can be used with Azure CLI. The script creates a new resource group, an Azure SQL Server, configures a firewall rule, and then creates a single SQL database with a General Purpose tier in a serverless compute model in the West US region. This setup is tailored for a development environment with minimal cost and appropriate resource allocation.

### Azure CLI Script for SQL Database Setup

1. **Set Up Variables**:
   ```sh
   let "randomIdentifier=$RANDOM*$RANDOM"
   location="West US"
   resourceGroup="youni-dev-rg-$randomIdentifier"
   tag="create-and-configure-database"
   server="youni-sql-server-$randomIdentifier"
   database="younidb$randomIdentifier"
   login="azureuser"
   password="Pa$$w0rD-$randomIdentifier"
   startIp=0.0.0.0
   endIp=0.0.0.0
   ```

2. **Create Resource Group**:
   ```sh
   az group create --name $resourceGroup --location "$location" --tags $tag
   ```

3. **Create SQL Server**:
   ```sh
   az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password
   ```

4. **Configure Firewall Rule**:
   ```sh
   az sql server firewall-rule create --resource-group $resourceGroup --server $server -n AllowYourIp --start-ip-address $startIp --end-ip-address $endIp
   ```

5. **Create SQL Database**:
   ```sh
   az sql db create \
       --resource-group $resourceGroup \
       --server $server \
       --name $database \
       --sample-name AdventureWorksLT \
       --edition GeneralPurpose \
       --compute-model Serverless \
       --family Gen5 \
       --capacity 2
   ```

Adjust the `startIp` and `endIp` values to match your specific IP address range for security.
