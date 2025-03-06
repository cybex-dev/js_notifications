# Notes

## Testing

Running tests with dart can be done using the following command:

```bash 
dart test
```

Unfortunately, due to a service worker being required, the tests will not run as expected. This is because the service worker is not registered at the time of running the test - this will be addressed in future as tests are fundamental for this type of feature. This can be observed with:
```bash
flutter test --platform chrome
```


