# Synchronization between BIIGLE instances

The [`biigle/sync`](https://github.com/biigle/sync) module allows the synchronization of users, label trees and volumes between BIIGLE instances. The module is installed by default if you use [`biigle/biigle`](https://github.com/biigle/biigle).

## Use case

The synchronization feature was originally developed for an on-shore/off-shore setup of BIIGLE instances. One BIIGLE instance is installed on a ship which is going on a research cruise (off-shore). Another instance is installed at a research institute (on-shore). Before the cruise starts, users and label trees are exported from the on-shore instance and imported in the off-shore instance. During the cruise, image and video data is collected and (partly) annotated in the off-shore instance. New users or label trees may be added as well as existing label trees may be modified. Once the cruise is complete, the data should be migrated back to the on-shore instance. There, the new volumes, label trees and users should be created as well as the modified label trees be updated. All this can be achieved with the synchronization feature.

## Usage

Synchronization is achieved through export files which are ZIP archives that contain data in JSON and CSV format. Export files can be generated in the admin area ("Export" in the menu on the left). You can choose to export only users, label trees (which also include the users who are associated with the label tree) or whole volumes (which also include the label trees and users which are associated with the volume/annotations). The volume export is the most common to move information about images, videos and their annotations to another BIIGLE instance. An export file can be uploaded in the admin area ("Import" in the menu on the left) to initiate an import.

!!! danger "Caution"
    All export files contain user password hashes. Keep them secure to prevent unauthorized access. Delete the files after the import is done.
   
The user export can be used to copy user accounts from one BIIGLE instance to another. The users will be able to log in using the same email address and password. This export can also be used to synchronize users for [federated search](/federated-search). 

The label tree export contains all information about the label tree and its labels as well as the label tree members. On import, all members that also exist on the other BIIGLE instance will be added as members of the imported label tree. The label tree admins are always imported (unless they already exist in the instance). If the same label tree already exists in the instance, the import allows you to update the existing label tree with added, deleted or modified labels of the label tree that should be imported.

The volume export contains information about all images, videos and annotations of one or many volumes. The label trees and users who are associated with the annotations are included as well. When volumes are imported, all label trees and users that are associated with the annotations in the volumes are also imported (unless they already exist in the BIIGLE instance). Volumes are exported independent of the projects to which they belong in the "source" BIIGLE instance. Hence, a new project must be specified during import to which the volume(s) should be attached.
