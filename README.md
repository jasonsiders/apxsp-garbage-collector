# apxsp-garbage-collector

> "You can never have too much information..."

That's what I thought until early on in my career, when my company came under pressure from Salesforce because we exceeded our [Data and File Storage Allocation](https://help.salesforce.com/s/articleView?id=sf.overview_storage.htm&type=5&language=en_US). This is a relatively common problem in the Salesforce ecosystem.

Introducing `apxsp-garbage-collector` - a metadata driven solution to data storage problems. This framework provides a way to quickly create batch jobs to handle stale data. Simple jobs can be created or modified in metadata, without touching a single line of code. The framework can be easily extended to handle more complex use cases.

## Getting Started

### **For General Use**

`apxsp-garbage-collector` is available as an unlocked package. See [Releases](https://github.com/jasonsiders/apxsp-garbage-collector/releases) for the latest install link.

Note: You must first install any dependencies listed in the [sfdx-project.json](https://github.com/jasonsiders/apex-starter-pack/blob/main/sfdx-project.json) file.

### **For Development**

When contributing to `apxsp-garbage-collector`, follow these steps:

1. Sign in to a Salesforce [Dev Hub](https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/dev_hub_intro.htm).
    - If you don't have access to a DevHub, create a free [Developer Edition](https://developer.salesforce.com/signup) org. Once created, follow the steps to [enable DevHub features](https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/sfdx_setup_enable_devhub.htm).
2. Create a [new scratch org](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch_orgs_create.htm):

```
sfdx force:org:create -f config/project-scratch-def.json -w 60 --durationdays 30 --loglevel fatal --json --nonamespace --setdefaultusername --setalias {YOUR_ALIAS_HERE}
```

3. Run these commands to clone this repo, create a new branch, and push the code to your scratch org:

```
git clone https://github.com/jasonsiders/apxsp-garbage-collector.git
git checkout -b {YOUR_BRANCH_NAME}
sfdx force:source:push
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

See [LICENSE.md](LICENSE.md) for more details.
