# A sample of IaC in AWS Cloud with Terraform
The configuration code tries to implement the infrastructure that consists of follow components:
1. An Application Load Balancer facing internet users and forwording requests to web servers
    - Redirect HTTP request to HTTPS listener
    - Forward HTTPS request to Target group
1. A scaling group of EC2 instance hosting web servers
    - Instances are distributed in 2 Available Zones.
    - Instances allow only ingress from the Load Balancer
    - The web service redirects all 404 error to a fixed page.
1. A serverless RDS instance
    - Allow only connect from the scaling group instances.

## Keep in mind:
1. For each web server SSH port is open to public internet for debug and troubleshooting, which I don't recommand in production.
1. It is never recommended to save database password in plain text and use admin to connect database for an application in production. although I've done in the demo
1. In my mind, application deployment should be separated from infrastructure provision. For convinence to demo the infrastructure and web application in limited time, I combine both into one project. 
1. Region and Available zones are hard-coded, so you may need change to your favoriate.

## Usage
1. Obtain neccessary permissions in IAM for the account role to provision resources:
    + EC2
    + RDS
    + CertificateManager
    + NetworkManager
    + ElasticLoadBalancing

1. Prepare a self-signed certificate for HTTPS.
    + Use openssl to generate private.key, certificate.csr and certificate.crt in order:
      > openssl genrsa -out private.key 2048
      > openssl req -new -key private.key -out certificate.csr
      > openssl x509 -req -days 366 -in certificate.csr -signkey private.key -out certificate.crt
    + In AWS Certificate Manager(ACM) console, Select **Import certificate** and paste the contents of private.key and certificate.crt in _Certificate private key_ and _Certificate body_ to get a Certificate in ACM.
1. Use ARN of the imported certificate as input variable *web_certificate_ar* for terraform run.
   Suggest create a file "*.tfvars" locally to specify all neccessary varaibles values via `-var-file` parameter , for example:
    ```
    web_certificate_arn = "arn:aws:acm:us-east-2:013902335248:certificate/d947eeb6-0a44-4840-9f6d-6c820b0ae93e"
    db_pass = "123qweasd"
    db_user = "admin"
    ```
1. Run terraform init, plan, apply and destroy when neccessary.
1. Terraform apply Output includes:
    - **web_url**: for user to visit the web application
    - **mysql_connection**: for developer to connect the MySQL database(only accessible from a web server)

## Expected user experience
1. Use the **web_url** to visit the web site.
1. User need accept the **certificate risk** to vist the site, because of the self-signed certificate.
1. **Home page** will present 
    + **Instance id** of the backend web server, which may vary every time refresh or access the site.
    + Total visit record **number** which is incresed automatically and saved in database
1. Accessing any non-existing page will be redirected to a fixed **404** page where there is a link to Home page
1. Requesting to **HTTP** will be redirected to HTTPS protocol

## Demo results
Demo results are presented in the folder [demo-results](demo-results)

# Troubleshoot tips
1. To login the web server through SSH
    + Before provision, add or replace with your public key to *ssh_authorized_keys* in file [scaling.tf](scaling.tf)
    + After provision, find the public ip addresss in EC2 console
    + Login with your private key and **ubuntu** user which have sudo priviledge
1. To connect MySql database instance
    + Login one web server via SSH
    + From the web server, connect to the database with **mysql_connection** and the password
    + _Database_ **wanted** is used to save user data in _table_ **user_ips**


## Further to do
1. Add TLS between web server and RDS
1. Move Scaling group to private group to reduce cost for ip address and internet risk.
1. Implement a CICD strategy to  update web service and Database
1. Add automatic scaling rules to scaling group