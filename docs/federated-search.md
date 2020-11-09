# Federated search

The BIIGLE federated search allows you to share the search index for projects, label trees and volumes between different BIIGLE instances. This enables users to find their projects, label trees and volumes of a BIIGLE instance _A_ by using the search of a BIIGLE instance _B_. The users need accounts that are synchronized between the BIIGLE instances (see [below](#synchronizing-users-between-biigle-instances)).

## Setting up the federated search

Two BIIGLE instances can be connected for federated search in the admin area. There, click on "Federated Search" in the navigation on the left. To connect a new instance, choose a name and enter the base URL (e.g. `https://biigle.de`) of the instance in the input fields on the right, then click "Connect". Both instances need to be connected to the respective other instance this way. Next, configure how the search index of the two instances should be shared with the "[access](#access)" and "[indexing](#indexing)" options.

### Access

Enable the access option to allow the remote instance to retrieve the search index of the local instance. When activated, an access token will be displayed (only once). This token can be used to enable the [indexing](#indexing) option of the remote instance.

### Indexing

Enable the indexing option to start the regular retrieval of the search index from the remote instance. This requires an access token that is obtained by enabling the [access](#access) option of the remote instance. The search index will be updated hourly. Once this option is activated, users of the local instance will be able to find their projects, label trees and volumes of the remote instance by using th search of the local instance. The users only see the projects, label trees and volumes that they are authorized to access.

## Synchronizing users between BIIGLE instances

In order to manage the access authorization (i.e. which users are able to see which projects, label trees, volumes of the remote instance), users need to be synchronized between the two BIIGLE instances that are connected for federated search. This means that the users who should be able to use the federated search need accounts in both BIIGLE instances and the UUIDs of the user accounts must match.

Use the [user export/import](/sync) to create user accounts with matching UUIDs. In the BIIGLE instance where the user accounts exist, create an export with the respective users. Then, import the file in the other BIIGLE instance where the user accounts do not exist, yet. This will create the user accounts with their correct UUID so they can access federated search results.

## Behind the scenes

Under the hood, a BIIGLE instance that allows access to its search index by another instance generates a condensed search index once an hour (at minute 55). This index contains information about the names and descriptions of projects, label trees and volumes as well as their URLs and the UUIDs of the users who are authorized to access them.

The BIIGLE instance that is configured to retrieve this search index does so once an hour (at minute 05). The information about the "models" (projects, label trees, volumes) in the index are used to populate special database tables that are associated with the local users who are authorized to access them. Search results in the local BIIGLE instance will then include results from these model tables and add them to the regular search results of the instance. A click on such a model will redirect the user to the respective view (e.g. project overview) of the remote BIIGLE instance.

Users can choose to include or hide search results of BIIGLE instances connected for federated search. When an instance is disconnected (i.e. deleted) in the admin area, the federated search models will be immediately deleted in the local database.
