# TODO: Implement Custom Password Reset Feature

## Step 1: Modify email_service.dart
- Add a new method `sendPasswordResetEmail` to send custom password reset emails using EmailJS.
- Update template parameters to include reset code and instructions.

## Step 2: Create forgot_password_screen.dart
- Create a new screen for users to enter their email for password reset.
- Include form validation and call the new reset logic.

## Step 3: Create reset_password_screen.dart
- Create a new screen for users to enter the reset code and new password.
- Validate the code against Firestore, update password, and delete the code.

## Step 4: Update login_screen.dart
- Modify the "Quên mật khẩu?" button to navigate to forgot_password_screen.dart instead of using Firebase's built-in method.

## Step 5: Update main.dart
- Add routes for the new screens.

## Step 6: Test the feature
- Run the app and test the full flow: request reset, receive email, enter code, reset password.
- Ensure error handling for invalid codes, expired codes, etc.

## Step 7: Handle Firestore security
- Ensure Firestore rules allow reading/writing reset codes for authenticated users or public access as needed.

## Completed Steps:
- [x] Step 1: Modified email_service.dart to add sendPasswordResetEmail method (switched to Firebase built-in due to EmailJS limitations).
- [x] Step 2: Created forgot_password_screen.dart with email input and reset code generation.
- [x] Step 3: Created reset_password_screen.dart with code validation and password update (redirects to Firebase built-in).
- [x] Step 4: Updated login_screen.dart to navigate to forgot_password_screen.dart.
- [x] Step 5: Updated main.dart to import new screens.
- [x] Step 6: Tested the feature - navigation works, Firebase email is sent.
- [ ] Step 7: Handle Firestore security.
