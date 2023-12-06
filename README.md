TUTORIAL:
HOW TO USE AND WRITE CUSTOM TERRAFORM MODULES

We shall provision some infrastructure and then refactor our code into a modular structure.

1.Why use Terraform modules?

- Standardisation 
- Encapsulate logic
- Code reuse
- Makes updates easy

It’s quite common for companies to have very specific rules for how resources should be configured. For instance, a company might have a policy of only deploying AWS S3 buckets without public access and with encryption enabled.

As a DevOps engineer, you could declare this S3 configuration over and over again in your Terraform code, but there’s a risk of missing some of the requirements at some point. Or you could use a much better approach and create an AWS S3 bucket module that has the company’s required configuration, and then use this module for all your future deployments.
By creating a module that encapsulates the company’s specific requirements for S3 buckets, you can ensure that all your deployments adhere to the rules set by the company. It also makes it easier to update the company’s requirements in the future, as you only need to make the changes to the module, instead of having to update all the instances of the configuration throughout your code.


TODAY'S TASK
----------------

1. Create and provision a basic EC2 resource in one public subnet in a VPC in AWS
2. Refactor the EC2 resource and VPC resources into modules
3. Create the updated infrastructure using the modules with different parameters.

### Create provider  provider.tf

TUTORIAL:
HOW TO USE AND WRITE CUSTOM TERRAFORM MODULES

We shall provision some infrastructure and then refactor our code into a modular structure.

1.Why use Terraform modules?
- Standardisation 
- Encapsulate logic
- Code reuse
- Makes updates easy

It’s quite common for companies to have very specific rules for how resources should be configured. For instance, a company might have a policy of only deploying AWS S3 buckets without public access and with encryption enabled.

As a DevOps engineer, you could declare this S3 configuration over and over again in your Terraform code, but there’s a risk of missing some of the requirements at some point. Or you could use a much better approach and create an AWS S3 bucket module that has the company’s required configuration, and then use this module for all your future deployments.
By creating a module that encapsulates the company’s specific requirements for S3 buckets, you can ensure that all your deployments adhere to the rules set by the company. It also makes it easier to update the company’s requirements in the future, as you only need to make the changes to the module, instead of having to update all the instances of the configuration throughout your code.


TODAY'S TASK
----------------

1. Create and provision a basic EC2 resource in one public subnet in a VPC in AWS
2. Refactor the EC2 resource and VPC resources into modules
3. Create the updated infrastructure using the modules with different parameters.


### Create provider  provider.tf

# Configure the AWS Provider
```
provider "aws" {
  region = "us-east-1"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Create 2  EC2 Instances 
### create my_ec2.tf
```
touch my_ec2.tf
```

```
resource "aws_instance" "my_instance" {
  count = var.ec2_count
  ami           = var.ami
  instance_type = var.instance_type
subnet_id = aws_subnet.public.id
  tags = {
    Name = "my_EC2-${count.index}"
  }
}
```
### create variables.tf to give default values to our variables

```
touch variables.tf
```

### Variables.tf should look like this below
```
variable "ami" {
  default = "ami-0fc5d935ebf8bc3bc"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "ec2_count" {
  default = 2
}
```
### Next we shall create one VPC, one public subnet, Internet Gateway and public Route table
### networking.tf

### Create networking.tf

```
touch networking.tf
```

### Create the VPC
```
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "main_vpc"
  }
}
```
### Create the public subnet
```
resource "aws_subnet" "public" {
    
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr

  tags = {
    Name = "Main_public_subnet"
  }
}
 ```
 ### Create internet gateway
 ```
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_igw"
  }
}
```
### Public route table
```
resource "aws_route_table" "rtb-public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public-RT"
  }
}
resource "aws_route" "rtb-public-route" {
  route_table_id         = aws_route_table.rtb-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rtb-public.id
}

```



### Let's update variables.tf to include the variables in networking.tf
```
variable "ami" {
  default = "ami-0fc5d935ebf8bc3bc"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "ec2_count" {
  default = 2
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}
```
### Let's run the commands to create the EC2 Instance in AWS. We shall create and then convert our code to a module

terraform init
Initialise backend, provider plugins and any modules

terraform plan
Do a dry run of the resources to be created

terraform apply -auto-approve
Create the infrastructure

### Let us check the created instances in the AWS console




### Now, if any other person needs to create a similar EC2 instances, they will need to duplicate the code by creating another EC2 resource and may not even comply to company standards while creating the instance.

### With a module, different teams can use the same module and only need to supply its parameters i.e values for it's variables.


### Let us refactor our instance code into a module.

step 1  - create a 2 folders to contain the resources relating to the instance and vpc  my_ec2 and my_vpc
step 2. - create our modules in main.tf in the root folder which will call the resources in our modules
step 3 - Run our refactored configuration.


### Step 1 Create folder my_ec2 in root

```
mkdir my_ec2
```
### move  my_ec2.tf which contains our resource code into my_ec2 folder
```
mv my_ec2.tf my_ec2/
```
my_ec2.tf is now in my_ec2/ 

### We shall cd into my_ec2/ to create a variable file.
### We wouldn't create any defaults as we want to pass this in runtime

### In my_ec2/my_ec2.tf
```
resource "aws_instance" "my_instance" {
  count = var.ec2_count
  ami           = var.ami
  associate_public_ip_address = true
  instance_type = var.instance_type
subnet_id = var.instance_subnet_id
  tags = {
    Name = "my_EC2-${count.index}"
  }
}
```


```
touch variables.tf
```
### in my_ec2/variables.tf
```
variable "ami" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "ec2_count" {
  type = number
}

variable "instance_subnet_id" {
  type = string
}
```
### Create foldermy_vpc
### We also need to move networking.tf into my_vpc folder
```
mv networking.tf my_vpc/
```
### networking.tf
```
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "public" {
    
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr

  tags = {
    Name = "Main_public_subnet"
  }
}
 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_igw"
  }
}

resource "aws_route_table" "rtb-public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public-RT"
  }
}
resource "aws_route" "rtb-public-route" {
  route_table_id         = aws_route_table.rtb-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rtb-public.id
}
```
### we need to output the subnet ID to be consumed by the my_ec2 module
```
cd my_vpc
```
```
touch output.tf
```

### output.tf
```
output "public_subnet_id" {
  value = aws_subnet.public.id
}
```
### Now we shall create main.tf in the root folder and create our modules there.

### The modules will call our ec2 and vpc resources using the source attribute.

Go back to root folder

```
cd..
```
### create main.tf

```
touch main.tf
```

### main.tf

```
module "my_ec2_module" {
  source = "./my_ec2"
  ec2_count = var.ec2_count
  instance_type = var.instance_type
  instance_subnet_id = module.my_vpc_module.public_subnet_id
  ami = var.ami
}

module "my_vpc_module" {
  source = "./my_vpc"
  vpc_cidr = var.vpc_cidr
  subnet_cidr = var.subnet_cidr
  
}
```

### Edit variables.tf in root to remove the default values
### edit as below
```
variable "ami" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "ec2_count" {
  type = number
}
variable "vpc_cidr" {
  type = string
}
variable "subnet_cidr" {
  type = string
}

```

### Now we shall set the module values using a tfvars file

### Create terraform.tfvars file and set values for variables

```
touch terraform.tfvars
```

### Now we can set the values in the tfvars file and use in diffrent environments whenever ec2 instances are needed in a VPC. 

### Terraform will look into the tfvars file for the values of the variables

### terraform.tfvars
```
ami = "ami-0fc5d935ebf8bc3bc"      ###You can get one from the AWS console
instance_type = "t2.micro"
ec2_count = 2
vpc_cidr ="10.0.0.0/16"
subnet_cidr ="10.0.1.0/24"
```

### Now we run the Terraform commands to create our instance and vpc using the modules
```
terraform init
Initialise backend, provider plugins and our my_ec2_module

terraform plan
Do a dry run of the resources to be created

terraform apply -auto-approve
Create the infrastructure
```

### EC2 instance was created successfully. 

### Now you can create different versions of your infrastructure by simply changing the values in terraform.tfvars
### Infrastructure will be created with the new configuration

Success!!! 
You have learnt how to create  basic reusable Terraform modules

The module solves the problem of having to write a common process over and over again.

However, there is still another problem

In a multi environment setup, we could have environments such as production, staging and development
If we need to replicate our infrastructure using the same module, we will run into problems as terraform will overwrite any existing infrastructure which isn't the desired effect.
We can overcome this by having a seperate Terraform code and statefiles for each environment.

This however is code duplication and shouldn't be done except in special cases.

The way to overcome this problem is to use Terraform Workspaces.
With workdpaces, we can use the same terraform configuration but with different statefiles for each environment.

I will continue this class in part 2 of this tutorial.

Please subscribe to be notified when the part 2 drops.

