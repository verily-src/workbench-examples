==NOTE - this file is intended to be used as input for the vwb_8b_v100_llama31_hf.ipynb notebook==

## What is Verily Workbench?
Verily Workbench is a secure research environment for governing and analyzing global multimodal biomedical data. Our mission is to transform biomedical research by making the world’s most scientifically valuable data discoverable, accessible, and analyzable. We aspire to enable the next generation of secure biomedical research and set the de-facto standard for health data analysis in the world by supporting the collaborative analysis of data from many sources, organizations, and geographies, respecting regulatory and ethical policies. To realize that vision, we support the end-to-end lifecycle of data that is governed, research that is reproducible, and collaboration that is easy & secure for commercial enterprises.

Verily Workbench grew out of our work supporting important scientific initiatives, including our work on the Researcher Workbench for the All of Us Research Program, in collaboration with Vanderbilt University Medical Center and others. That work led to a deep understanding of the needs of academic researchers and how to meet them, including:
* Support for **varying levels of computational expertise**, from point-and-click interfaces for non-technical domain experts to customizable programming tools for computational experts.
* Support for a flexible **Data Explorer** to enable cohort and dataset building on multiple data sources and data models. The Data Explorer has been developed and tested on a variety of data including All of Us and VUMC’s SD.
* Support for **multimodal data**, including EHR data, whole-genome sequences, participant surveys, and digital health device data.
Support for ‘team science’, with **collaborative workspaces** for researchers to bring together the data, tools, and interim results of their analyses, with shared access by as few or as many collaborators as they choose.
* Support for the full power of **cloud computing**, wrapped with simple interfaces to hide the complexity until it’s needed. For example, researchers can use auto-provisioned single-machine compute backends by default, and they can configure compute {{< glossary_tooltip text="clusters" term_id="cluster" >}} of any size or shape if desired.

Building on our support for All of Us researchers, Verily explored the needs of commercial researchers in the pharma, biotech, and medical device industries. That exploration led to us adding the following key features and functionality:
* **Extensibility** to meet organization-specific needs, including single sign-on integration, custom data viewers, cohort-specific data explorers, and bring-your-own analysis tools.
* **Data governance** controls, including the ability for data owners to define multiple {{< glossary_tooltip text="data collections" term_id="data-collection" >}}, to define auto-enforced collection-specific {{< glossary_tooltip text="policies" term_id="policy" >}}, and to track access to data and data derivatives.
* **Infrastructure** flexibility, including support for Google Cloud Platform and/or Amazon Web Services.
* **Operational hardening**, including improved reliability, and security and compliance certifications.

With all of these features, data generating organizations, research sponsors, and biomedical researchers can use Workbench to securely connect with stakeholders and partners, explore and analyze multimodal data, and simplify data governance with access control and policy enforcement. Workbench users can tap into a growing ecosystem of data sources and researchers, to build on collective scientific progress, share best practices, and conduct reproducible research. They can:
* **Cross-analyze** their internal data against a multimodal external data ecosystem to uncover new insights.
* **Connect** stakeholders and partners, and integrate domain-specific analysis tools to easily build and share best practices.
* Enable data governance with features to **control** access, enforce policies, and monitor data {{< glossary_tooltip text="lineage" term_id="lineage" >}}.
* Build on **collective progress** by tapping into a growing network of data sources, researchers and reproducible methods.

## What are Verily Workbench's capabilities?

### Multimodal Data Framework
An increasing amount of biomedical data is being produced by different systems in a variety of volumes, velocities, and varieties. These diverse data are then stored in disconnected locations creating data silos making it very difficult for researchers to access, integrate, and analyze to create meaningful insights. The increasing amount of data is putting significant pressure on IT organizations to provide infrastructure, software, and analysis tools to meet researchers' needs.

Workbench enables data stewards to organize their data across many modalities along with supporting metadata and artifacts like quality reports in a unified data platform with built-in support for biomedical data types.

Capabilities include:
* Research-ready {{< glossary_tooltip text="data collections" term_id="data-collection" >}} that support dataset versioning
* Support for multiple data modalities and schemas, including:
  * omics (e.g., BAM, CRAM, VCF)
  * clinical (e.g., CSV/TSV, PDF, OMOP, CDISC)
  * imaging (e.g., DICOM, JPG)
* Workspace {{< glossary_tooltip text="resources" term_id="resource" >}} and folders
* Workbench resource {{< glossary_tooltip text="lineage" term_id="lineage" >}}
* Self service data onboarding
* File import using GA4GH Data Connect

### Data Exploration
As research teams consider a growing set of real-world data sources, it’s important to help them quickly identify the value in their data. Unfortunately, data – especially from multimodal repositories – are often hard to explore, because they’re stored in a variety of systems and data models that require detailed understanding and meticulous coding to query. Even a simple question, like “how many individuals in this dataset have been diagnosed with disease X, treated with drug Y, and have gene variant data available”, can take hours or days to answer.

To address this, Workbench comes with a powerful, tuneable Data Explorer. Inspired by the popular Cohort Builder tool that Verily built for All of Us, the Data Explorer makes it easy for data owners to offer researchers an easy-to-use, interactive way to rapidly answer exploratory questions about the data. For more complex analysis tasks, the Data Explorer facilitates a hand-off of relevant data to the researcher’s tools of choice via the Workbench.

Capabilities include:
* Intuitive, interactive web interface with data visualizations
* Flexible data model support, including extensive OMOP capabilities and multimodal data integration
* Interactive data selection using set and Boolean logic, including:
  * Building cohorts of individuals relevant to case and control groups
  * Selecting relevant data features for a study
  * Combining cohorts and data features to assemble an export-ready data subset
  * Reviewing and annotating individual-level data
* Extensible export options, including SQL generation, CSV files, and cloud relational database systems
* Flexible access controls, including option to limit data access depending on the user’s access or license level

### Scalable Biomedical Analysis
A unique attribute of scientific research is that the rapid development of novel data necessitates the development of novel tools to extract meaning from those data. Researchers find it difficult to meet their analysis needs because they can’t bring the tools they need to this new data, especially when analysis requires compute or storage in the cloud.

Workbench enables researchers to leverage a wide range of tools, from general data science tools like {{< glossary_tooltip text="JupyterLab" term_id="jupyterlab" >}} to biomedical best-in-class tools that are pre-integrated, along with an extensible application framework that enables users to develop & deploy their own tools.

Capabilities include:
* Access to public cloud scale (e.g., petabytes of storage, 100K {{< glossary_tooltip text="CPUs" term_id="central-processing-unit-cpu" >}}, global datacenter footprint) with native integrations with Google Cloud and AWS that support complex scientific analyses such as variant calling and genome wide association studies
* Built-in analysis tools, e.g.,
  * Vertex AI Notebook / JupyterLab
  * Spark clusters
  * Visual Studio Code
* Extensible app framework / bring your own license, e.g., R Analysis Environment, SAS
* Autoconnect cloud data storage to cloud compute
* File preview, including: CSV, PDF, JSON, BAM, CRAM
* Application Library

### Global Governance, Compliance, and Security
Research leaders are struggling to keep up with developing, monitoring and enforcing the increasing amounts, types, and uses of biomedical data, the number of locations and applications that are storing and using the data, and the increasing compliance requirements of a globally connected research community.

Workbench enables data stewards to associate the {{< glossary_tooltip text="policies" term_id="policy" >}} that govern their data to their data, which lets researchers focus on their science. Data stewards govern & monitor global data dynamically for secure, compliant collaboration inside & outside your organization.

Capabilities include:
* Workbench Policy Service
  * {{< glossary_tooltip text="Group" term_id="group" >}} Membership
  * Geographic Regions
  * Cloud {{< glossary_tooltip text="Perimeter" term_id="perimeter" >}}
* Workbench Activity Monitor for auditing and tracking data access & activity
* Supports compliance requirements for:
  * ISO 27001 / SOC2
  * GDPR
  * HIPAA / BAA
* Active member of Data Privacy Framework: EU-US, Swiss-US.

### Enterprise Ready Integrations
Massive fragmented IT infrastructure creates data & analysis silos with compliance risks that slow research and prevent cross-org collaboration. Research teams are under immense pressure to move quickly but run into major headwinds when working with well-intentioned but overwhelmed IT support teams.

Workbench provides seamless industry-standard integration points with common enterprise identity, data, tool systems, and IT infra, with multi-cloud support.

Capabilities include:
* Cloud support: Google Cloud (Generally Available), AWS (Private Preview)
* Federated identity providers (Auth0)
* Source code management (git)
* Flexible cloud infrastructure, e.g., bring your own billing, leverage your cloud configuration.

### Secure Collaboration
Legacy tools and data management systems primarily built for internal only usage struggle to support and govern the information sharing and privacy needs of global teams & multi-organization partnerships. This constrains the value organizations can get from data because people can’t work with other experts on their team or in other organizations without spending endless cycles of time with legal and IT teams.

Workbench enables organizations to securely share data, code, and tools with internal and external collaborators through {{< glossary_tooltip text="workspaces" term_id="workspace" >}} that are governed by the policies, data use agreements, and organizational requirements associated with all referenced data collections.

Capabilities include:
* Workspaces with role-based access control and integrated policy support
* Getting Started workspaces customized to your data & tools that jumpstart research
* Sharable applications & dashboards
* Organization data & application library

### Self-Service Interfaces
Existing biomedical data & analysis tools often support a very narrow user base by focusing on those with a high degree of computational knowledge. This prevents people with varying skillsets from getting value from data.

Workbench supports a wide range of users with different levels of tech, biomedical, and regulatory fluency. We invest deeply in user-centered design principles, conduct thorough user research leveraging our wide network of data stewards, privacy & legal counsel, clinical data managers, administrators, bioinformaticians, scientists, data sciences, computational researchers, and software engineers. We develop rich and intuitive web-based user interfaces that simplify complex tasks while also providing power users with access to Command Line Interfaces (CLIs) and direct access to their familiar tools, such as Google Cloud Console.

Capabilities include:
* Workbench Portal - our primary web-based UI
* Data Explorer – our data exploration and cohort-building web-based UI
* Workbench CLI
* Data onboarding & management
* User onboarding & management
* Org management
* Application onboarding & management
* Support Hub with Technical References, How-To Guides, Quick Starts, Best Practices, Tutorials and user support contact information.
