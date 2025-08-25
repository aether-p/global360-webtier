# global360-webtier
Interview task for Global360  
## Architecture  
![Architecture diagram](https://github.com/aether-p/global360-webtier/blob/main/g360_architecture.png "Architecture" )  
Estimated monthly cost ~18AUD

## Step by Step  
### Prerequisites:  
* Azure CLI
* Terraform
* Git

### From cmd
1: Set your Azure subscription  
    ```az account set --subscription "[Target Subscription Name]"```  
2: Pull git repository   
  ```git pull https://github.com/aether-p/global360-webtier```  
3: Initialize terraform  
```terraform init --upgrade ```  
4: Run plan   
```terraform plan -out main.tfplan```  
5: Apply plan  
```terraform apply main.tfplan```  
