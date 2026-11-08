# TechForge — Flutter Customer App + HTML Admin Dashboard

Two separate frontends sharing one Firebase project:
- `mobile/`: Flutter/Dart customer shopping app
- `admin/`: plain HTML, CSS, and JavaScript admin dashboard (no Node.js/npm)
- `firebase/`: Firestore security rules

The admin dashboard uses Firebase Authentication and Cloud Firestore directly through Firebase's browser SDK. Product images are entered as public image URLs; Firebase Storage is not used.

## Expected Firestore collections

`users/{uid}`: `fullName`, `email`, `phoneNumber`, `role` (`customer` or `admin`), `createdAt`

`products/{productId}`: `productName`, `brand`, `category`, `description`, `price` (number), `stock` (integer), `imageUrl`, `createdAt`, `updatedAt`

`orders/{orderId}`: `userId`, `customerName`, `contactNumber`, `deliveryAddress`, `items`, `totalAmount`, `paymentMethod`, `orderStatus`, `createdAt`, `updatedAt`

## Run the Flutter app
1. Install Flutter SDK and Android Studio.
2. Open a terminal in `mobile/`.
3. If platform folders are missing, run `flutter create .`.
4. Run `flutter pub get`.
5. Run `dart pub global activate flutterfire_cli` and `flutterfire configure` (select your TechForge Firebase project and Android app).
6. Run `flutter run`.
7. Build APK: `flutter build apk --release`.

## Run the web admin dashboard
1. Open the `admin/` folder in VS Code.
2. Install the **Live Server** extension.
3. Right-click `admin/index.html` and select **Open with Live Server**.
4. Sign in with the Firebase admin account.

No npm install or build command is needed. See `admin/README.txt` and `FIREBASE_SETUP.md` for setup instructions.
