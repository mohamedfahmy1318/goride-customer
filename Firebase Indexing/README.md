
# To perform Firebase indexing, follow these straightforward steps:
------------------------------------------------------------------

1. To set up NPM on your computer, download Node.js from the following link: https://nodejs.org/en/download/

2. Unzip the source code file named "Firebase Indexing.zip" here.

3. Navigate to the extracted directory of "Firebase Indexing" zip file. Press and hold the ctrl+shift buttons, then right-click the mouse button. From the context menu, select "Open PowerShell window here" to launch Windows PowerShell and execute import/export commands.

4. Execute the command "firebase login" to log in to Firebase, if you haven't already done so.

5. Execute the command "firebase init"

6.  Proceed with Y and press the enter button.

7. Choose the Option > Firestore: Configure security rules and indexes files for Firestore. 

Please Note: Choose the arrow down key to navigate and select options, and press the space button to confirm your selection.

8. Choose the Option > Use an existing project 

9.  Choose your project

10. Press Enter > ? What file should be used for Firestore Rules? firestore.rules

11. Press Enter > ? What file should be used for Firestore indexes? (firestore.indexes.json)

12. Now, the firestore.indexes.json file will be downloaded. Open this file and copy all the code from firestore_indexes.json file, then paste it into firestore.indexes.json file.

13. Now execute the command "firebase deploy --only firestore:indexes" to import indexing in firestore.
 
# Refer to this video for assistance: https://youtu.be/DeWVR5sNaFg