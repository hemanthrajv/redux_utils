# Redux Utils

Redux Utils helps to setup basic boiler plate to use `redux.dart` with `flutter`.

Note: Still experimenting. Suggestions and PR welcome.

## Installing

Specify the package in `dev_dependencies` like,

    redux_utils: 0.0.1


## Usage

Note: Use this tool only with new flutter projects, it does not support existing projects. Please commit the initial project before using this tool.

* First run `flutter packages get` after adding `redux_utils` to `dev_dependencies`
* From root of the flutter project run `flutter pub pub run redux_utils:main`
* Then run `flutter packages get`
* Next, run `flutter pub pub run build_runner build`

Redux setup is done, you can start using the package.

### Packages Used
    dependencies:
        redux: '^3.0.0',
        redux_epics: '^0.10.0',
        flutter_redux: '^0.5.2',
        built_value: '^6.1.3',
        built_collection: '^4.0.0',
        shared_preferences: '0.4.2',
        rxdart: '^0.18.1',
        uri: '0.11.3+1',
        http: '^0.11.3+16',
        intl: '^0.15.7',

    dev_dependencies:
        build_runner: '^1.0.0',
        built_value_generator: '^6.1.4',
        flutter_launcher_icons: '^0.6.1',


### Folder Structure Used

    /actions
        - actions.dart
    /api
        - api_client.dart
    /data
        - app_repository.dart
        - preference_client.dart
    /middleware
        - auth_middleware.dart
        - middleware.dart
    /models
        - app_state.dart
        - models.dart
        - serializers.dart
    /reducers
        - reducers.dart
    /utils
        - assets.dart
        - icons.dart
        - utils.dart
    /views
        /login
            - login_page.dart
        /home
            - home_page.dart
        - init_page.dart
    - main.dart
    - routes.dart
    - theme.dart

## Author

**Hemanth Raj**
[StackOverflow](https://stackoverflow.com/users/8708524/hemanth-raj)

