# TODO List for Homestay Booking App Enhancements

## Phase 1: Remove Google/Facebook Login
- [x] Remove Google and Facebook login imports from login_screen.dart
- [x] Remove _loginWithGoogle and _loginWithFacebook methods
- [x] Remove Google and Facebook login buttons from UI

## Phase 2: Implement Favorites Functionality
- [ ] Add favorites collection to Firestore (userId, homestayId, timestamp)
- [ ] Update homestay card to show favorite status and toggle button
- [ ] Create favorites screen/view
- [ ] Add favorites to quick actions navigation

## Phase 3: Enhance Promotions
- [ ] Add promotions collection to Firestore with discount codes, validity
- [ ] Update promotion carousel with real data
- [ ] Add promotion details modal/screen
- [ ] Implement discount application in booking flow

## Phase 4: Add History Functionality
- [ ] Create search history collection (userId, searchQuery, timestamp)
- [ ] Create booking history view (enhance existing my_bookings_screen)
- [ ] Add history tracking to search and booking actions
- [ ] Add history to quick actions navigation

## Phase 5: Implement Quick Booking
- [ ] Create quick booking modal with date picker
- [ ] Add instant booking for available homestays
- [ ] Integrate with existing booking flow
- [ ] Add quick booking to quick actions

## Phase 6: Add Sample Data
- [ ] Add sample homestays with more variety
- [ ] Add sample promotions and discount codes
- [ ] Add sample user data for testing
- [ ] Test all new features

## Phase 7: Testing and Bug Fixes
- [ ] Test login without Google/Facebook
- [ ] Test favorites functionality
- [ ] Test promotions application
- [ ] Test history tracking
- [ ] Test quick booking
- [ ] Fix any UI/UX issues
