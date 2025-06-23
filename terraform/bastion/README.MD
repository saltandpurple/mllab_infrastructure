## Bastion setup using AWS SSM
Since the greedy bastards at AWS decided to take upwards of 200€/month for a client vpn with three subnets (without any connection hours!),
I'm using a bastion host with AWS SSM. This has several advantages:

1. Very cheap. t4g.micro is more than enough.
2. Simple to setup, no maintenance required (except perhaps some package updates on the ec2, but even that is irrelevant because of number 3)
3. No publicly exposed ports on the instance required (this is the real kicker, not even port 22)
4. Locally, you install `session-manager-plugin` (just use `brew install` on macos) & `sshuttle`
5. Setup your ssh-config like this:
```
Host aws-bastion
  HostName i-0123456789abcdef0 # obviously use your actual instance ID here
  User ec2-user # if you use Amazon Linux, otherwise adjust as needed
  ProxyCommand sh -c "aws ssm start-session --profile <YOUR_PROFILE> --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
  IdentityFile ~/.ssh/your-aws-key.pem
```
6. Use `sshuttle` to access all your stuff safely