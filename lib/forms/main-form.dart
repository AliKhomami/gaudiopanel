import 'package:after_layout/after_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gaudiopanel/forms/chwon-to-email.dart';
import 'package:gaudiopanel/forms/login.dart';
import 'package:gaudiopanel/forms/main-form-sections/profiles-data-section.dart';
import 'package:gaudiopanel/forms/profile-edit.dart';
import 'package:gaudiopanel/forms/search-params.dart';
import 'package:gaudiopanel/forms/upload-files.dart';
import 'package:gaudiopanel/models/common/paginated-items-response-model.dart';
import 'package:gaudiopanel/models/recitation/recitation-viewmodel.dart';
import 'package:gaudiopanel/models/recitation/uploaded-item-viewmodel.dart';
import 'package:gaudiopanel/models/recitation/user-recitation-profile-viewmodel.dart';
import 'package:gaudiopanel/services/auth-service.dart';
import 'package:gaudiopanel/services/storage-service.dart';
import 'package:gaudiopanel/services/upload-recitation-service.dart';
import 'package:gaudiopanel/services/recitation-service.dart';
import 'package:gaudiopanel/forms/main-form-sections/recitations-data-section.dart';
import 'package:gaudiopanel/forms/main-form-sections/uploads-data-section.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

enum GActiveFormSection {
  DraftRecitations,
  AllMyRecitations,
  AllUsersPendingRecitations,
  Uploads,
  Profiles,
  SynchronizationQueue
}

class MainForm extends StatefulWidget {
  @override
  MainFormWidgetState createState() => MainFormWidgetState();
}

class MainFormWidgetState extends State<MainForm>
    with AfterLayoutMixin<MainForm> {
  final GlobalKey<ScaffoldMessengerState> _key =
      GlobalKey<ScaffoldMessengerState>();
  bool _canModerate = false;
  bool _canImport = false;
  String _userFrinedlyName = '';
  bool _isLoading = false;
  GActiveFormSection _activeSection = GActiveFormSection.DraftRecitations;
  int _narrationsPageNumber = 1;
  int _uploadsPageNumber = 1;
  int _pageSize = 20;
  String _searchTerm = '';

  PaginatedItemsResponseModel<RecitationViewModel> _narrations =
      PaginatedItemsResponseModel<RecitationViewModel>(items: []);
  PaginatedItemsResponseModel<UploadedItemViewModel> _uploads =
      PaginatedItemsResponseModel<UploadedItemViewModel>(items: []);
  PaginatedItemsResponseModel<UserRecitationProfileViewModel> _profiles =
      PaginatedItemsResponseModel<UserRecitationProfileViewModel>(items: []);
  String get title {
    switch (_activeSection) {
      case GActiveFormSection.Uploads:
        return 'پیشخان خوانشگران گنجور » بارگذاری‌های من';
      case GActiveFormSection.Profiles:
        return 'پیشخان خوانشگران گنجور » نمایه‌های من';
      case GActiveFormSection.DraftRecitations:
        return 'پیشخان خوانشگران گنجور » خوانش‌های پیش‌نویس من';
      case GActiveFormSection.AllMyRecitations:
        return 'پیشخان خوانشگران گنجور » همهٔ خوانش‌های من';
      case GActiveFormSection.AllUsersPendingRecitations:
        return 'پیشخان خوانشگران گنجور » خوانش‌های در انتظار تأیید';
      case GActiveFormSection.SynchronizationQueue:
        return 'پیشخان خوانشگران گنجور » صف انتشار در گنجور';
    }
    return '';
  }

  Future<void> _loadNarrationsData() async {
    setState(() {
      _isLoading = true;
    });
    var narrations = await RecitationService().getRecitations(
        _narrationsPageNumber,
        _pageSize,
        _activeSection == GActiveFormSection.AllUsersPendingRecitations,
        _activeSection == GActiveFormSection.AllMyRecitations
            ? -1
            : _activeSection == GActiveFormSection.AllUsersPendingRecitations
                ? 1
                : 0,
        _searchTerm,
        false);
    if (narrations.error.isEmpty) {
      setState(() {
        _narrations.items.clear();
        _narrations.items.addAll(narrations.items);
        _narrations.paginationMetadata = narrations.paginationMetadata;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      _key.currentState.showSnackBar(SnackBar(
        content: Text("خطا در دریافت خوانش‌ها: " + narrations.error),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _loadUploadsData() async {
    setState(() {
      _isLoading = true;
    });
    var uploads = await RecitationService()
        .getUploads(_uploadsPageNumber, _pageSize, false);

    if (uploads.error.isEmpty) {
      setState(() {
        _uploads.items.clear();
        _uploads.items.addAll(uploads.items);
        _uploads.paginationMetadata = uploads.paginationMetadata;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      _key.currentState.showSnackBar(SnackBar(
        content: Text("خطا در دریافت بارگذاری‌ها: " + uploads.error),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _loadProfilesData() async {
    setState(() {
      _isLoading = true;
    });
    var profiles = await RecitationService().getProfiles(_searchTerm, false);

    if (profiles.item2.isEmpty) {
      setState(() {
        _profiles.items.clear();
        _profiles.items.addAll(profiles.item1);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      _key.currentState.showSnackBar(SnackBar(
        content: Text("خطا در دریافت نمایه‌ها: " + profiles.item2),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _loadSyncronizationQueueData() async {
    setState(() {
      _isLoading = true;
    });
    var narrations = await RecitationService().getSynchronizationQueue(false);
    if (narrations.item2.isEmpty) {
      setState(() {
        _narrations.items.clear();
        _narrations.items.addAll(narrations.item1);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      _key.currentState.showSnackBar(SnackBar(
        content: Text("خطا در دریافت صف انتشار در سایت: " + narrations.item2),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _loadData() async {
    switch (_activeSection) {
      case GActiveFormSection.DraftRecitations:
      case GActiveFormSection.AllMyRecitations:
      case GActiveFormSection.AllUsersPendingRecitations:
        await _loadNarrationsData();
        break;
      case GActiveFormSection.Uploads:
        await _loadUploadsData();
        break;
      case GActiveFormSection.Profiles:
        await _loadProfilesData();
        break;
      case GActiveFormSection.SynchronizationQueue:
        await _loadSyncronizationQueueData();
        break;
    }
  }

  @override
  void afterFirstLayout(BuildContext context) async {
    var user = await StorageService().userInfo;
    if (user != null) {
      _userFrinedlyName = user.user.firstName + ' ' + user.user.sureName;
    }

    if (await AuthService().hasPermission('recitation', 'moderate')) {
      setState(() {
        _canModerate = true;
      });
    }
    if (await AuthService().hasPermission('recitation', 'import')) {
      setState(() {
        _canImport = true;
      });
    }
    await _loadData();
  }

  void _loadingStateChanged(bool isLoading) {
    setState(() {
      this._isLoading = isLoading;
    });
  }

  void _snackbarNeeded(String msg) {
    _key.currentState.showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  Future<UserRecitationProfileViewModel> _newProfile() async {
    return showDialog<UserRecitationProfileViewModel>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        ProfileEdit _profileEdit = ProfileEdit(
            profile: UserRecitationProfileViewModel(
                id: '00000000-0000-0000-0000-000000000000',
                name: '',
                artistName: '',
                artistUrl: '',
                audioSrc: '',
                audioSrcUrl: '',
                fileSuffixWithoutDash: '',
                isDefault: true));
        return AlertDialog(
          title: Text('نمایهٔ جدید'),
          content: SingleChildScrollView(
            child: _profileEdit,
          ),
        );
      },
    );
  }

  Future<bool> _getNewRecitationParams(
      UserRecitationProfileViewModel profile) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        UploadFiles _uploadFiles = UploadFiles(profile: profile);
        return AlertDialog(
          title: Text('ارسال خوانش‌های جدید'),
          content: SingleChildScrollView(
            child: _uploadFiles,
          ),
        );
      },
    );
  }

  Future<Tuple2<int, String>> _getSearchParams() async {
    return showDialog<Tuple2<int, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        SearchParams _searchParams =
            SearchParams(sparams: Tuple2<int, String>(_pageSize, _searchTerm));
        return AlertDialog(
          title: Text('جستجو'),
          content: SingleChildScrollView(
            child: _searchParams,
          ),
        );
      },
    );
  }

  Future<bool> _confirm(String title, String text) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(text),
          ),
          actions: [
            ElevatedButton(
              child: Text('بله'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: Text('خیر'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            )
          ],
        );
      },
    );
  }

  Future _newNarrations() async {
    setState(() {
      _isLoading = true;
    });
    var profileResult = await RecitationService().getDefProfile(false);
    setState(() {
      _isLoading = false;
    });
    if (profileResult.item2.isNotEmpty) {
      _key.currentState.showSnackBar(SnackBar(
        content: Text('خطا در یافتن نمایهٔ پیش‌فرض ' +
            '، اطلاعات بیشتر ' +
            profileResult.item2),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (profileResult.item1 == null) {
      _key.currentState.showSnackBar(SnackBar(
        content: Text(
            'برای ارسال خوانش لازم است ابتدا نمایه‌ای پیش‌فرض تعریف کنید.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    var replace = await _getNewRecitationParams(profileResult.item1);
    if (replace == null) {
      return;
    }
    FilePickerResult result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'xml'],
    );
    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      String err = await UploadRecitationService()
          .uploadFiles(result.files, replace, false);

      if (err.isNotEmpty) {
        _key.currentState.showSnackBar(SnackBar(
          content: Text("خطا در ارسال خوانش‌های جدید: " + err),
          backgroundColor: Colors.red,
        ));
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future _deleteMarkedProfiles() async {
    var markedProfiles =
        _profiles.items.where((element) => element.isMarked).toList();
    if (markedProfiles.isEmpty) {
      _key.currentState.showSnackBar(SnackBar(
        content: Text('لطفاً نمایه‌های مد نظر را علامتگذاری کنید.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    String confirmation = markedProfiles.length > 1
        ? 'آیا از حذف ' +
            markedProfiles.length.toString() +
            ' نمایهٔ علامتگذاری شده اطمینان دارید؟'
        : 'آیا از حذف نمایهٔ «' + markedProfiles[0].name + '» اطمینان دارید؟';
    if (await _confirm('تأییدیه', confirmation)) {
      for (var item in markedProfiles) {
        var delRes = await RecitationService().deleteProfile(item.id, false);
        if (delRes.item2.isNotEmpty) {
          _key.currentState.showSnackBar(SnackBar(
            content: Text('خطا در حذف نمایهٔ ' +
                item.name +
                '، اطلاعات بیشتر ' +
                delRes.item2),
            backgroundColor: Colors.red,
          ));
        }
        if (delRes.item1) {
          setState(() {
            _profiles.items.remove(item);
          });
        }
      }
    }
  }

  Future _deleteMarkedRecitations() async {
    var markedRecitations =
        _narrations.items.where((element) => element.isMarked).toList();
    if (markedRecitations.isEmpty) {
      _key.currentState.showSnackBar(SnackBar(
        content: Text('لطفاً خوانش‌های مد نظر را علامتگذاری کنید.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    String confirmation = markedRecitations.length > 1
        ? 'آیا از حذف ' +
            markedRecitations.length.toString() +
            ' خوانش علامتگذاری شده اطمینان دارید؟'
        : 'آیا از حذف خوامش «' +
            markedRecitations[0].audioTitle +
            '» اطمینان دارید؟';
    if (await _confirm('تأییدیه', confirmation)) {
      for (var item in markedRecitations) {
        var delRes = await RecitationService().deleteRecitation(item.id, false);
        if (delRes.item2.isNotEmpty) {
          _key.currentState.showSnackBar(SnackBar(
            content: Text('خطا در حذف خوانش ' +
                item.audioTitle +
                '، اطلاعات بیشتر ' +
                delRes.item2),
            backgroundColor: Colors.red,
          ));
        }
        if (delRes.item1) {
          setState(() {
            _narrations.items.remove(item);
          });
        }
      }
    }
  }

  Future<String> _getEmail() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('انتقال مالکیت'),
          content: SingleChildScrollView(
            child: ChownToEmail(),
          ),
        );
      },
    );
  }

  Future _transferOwnership() async {
    var markedProfiles =
        _profiles.items.where((element) => element.isMarked).toList();
    if (markedProfiles.isEmpty) {
      _key.currentState.showSnackBar(SnackBar(
        content: Text('لطفاً نمایه‌های مد نظر را علامتگذاری کنید.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    String email = await _getEmail();
    if (email != null) {
      int transfered = 0;
      for (var profile in markedProfiles) {
        setState(() {
          _isLoading = true;
        });

        var ret = await RecitationService()
            .transferRecitationsOwnership(email, profile.artistName, false);

        setState(() {
          _isLoading = false;
        });

        if (ret.item2.isNotEmpty) {
          _key.currentState.showSnackBar(SnackBar(
            content: Text(ret.item2),
            backgroundColor: Colors.red,
          ));
          break;
        } else {
          transfered += ret.item1;
        }
      }

      _key.currentState.showSnackBar(SnackBar(
        content: Text('موارد منتقل شده: ' + transfered.toString()),
        backgroundColor: Colors.green,
      ));

      await _loadData();
    }
  }

  Widget get items {
    switch (_activeSection) {
      case GActiveFormSection.DraftRecitations:
      case GActiveFormSection.AllMyRecitations:
      case GActiveFormSection.AllUsersPendingRecitations:
      case GActiveFormSection.SynchronizationQueue:
        return RecitationsDataSection(
          narrations: _narrations,
          loadingStateChanged: _loadingStateChanged,
          snackbarNeeded: _snackbarNeeded,
          status: _activeSection == GActiveFormSection.DraftRecitations
              ? 0
              : _activeSection == GActiveFormSection.AllUsersPendingRecitations
                  ? 1
                  : -1,
        );
      case GActiveFormSection.Profiles:
        return ProfilesDataSection(
            profiles: _profiles,
            loadingStateChanged: _loadingStateChanged,
            snackbarNeeded: _snackbarNeeded);
      case GActiveFormSection.Uploads:
      default:
        return UploadsDataSection(uploads: _uploads);
    }
  }

  String get currentPageText {
    if (_narrations != null &&
        _narrations.paginationMetadata != null &&
        (_activeSection == GActiveFormSection.DraftRecitations ||
            _activeSection == GActiveFormSection.AllMyRecitations ||
            _activeSection == GActiveFormSection.AllUsersPendingRecitations)) {
      return 'صفحهٔ ' +
          _narrations.paginationMetadata.currentPage.toString() +
          ' از ' +
          _narrations.paginationMetadata.totalPages.toString() +
          ' (' +
          _narrations.items.length.toString() +
          ' از ' +
          _narrations.paginationMetadata.totalCount.toString() +
          ')';
    }
    if (_activeSection == GActiveFormSection.Uploads &&
        _uploads != null &&
        _uploads.paginationMetadata != null) {
      return 'صفحهٔ ' +
          _uploads.paginationMetadata.currentPage.toString() +
          ' از ' +
          _uploads.paginationMetadata.totalPages.toString() +
          ' (' +
          _uploads.items.length.toString() +
          ' از ' +
          _uploads.paginationMetadata.totalCount.toString() +
          ')';
    }

    if (_activeSection == GActiveFormSection.SynchronizationQueue &&
        _narrations != null) {
      return _narrations.items.length.toString() + ' مورد';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
        key: _key,
        child: LoadingOverlay(
            isLoading: _isLoading,
            child: Scaffold(
              appBar: AppBar(
                title: Text(title),
                actions: [
                  IconButton(
                      icon: Icon(Icons.refresh),
                      tooltip: 'تازه‌سازی',
                      onPressed: () async {
                        await _loadData();
                      }),
                  Visibility(
                    child: IconButton(
                        icon: Icon(Icons.check_box),
                        tooltip: 'علامتگذاری همه',
                        onPressed: () {
                          if (_activeSection == GActiveFormSection.Profiles) {
                            for (var item in _profiles.items) {
                              setState(() {
                                item.isMarked = true;
                              });
                            }
                          } else {
                            for (var item in _narrations.items) {
                              setState(() {
                                item.isMarked = true;
                              });
                            }
                          }
                        }),
                    visible: _activeSection != GActiveFormSection.Uploads &&
                        _activeSection !=
                            GActiveFormSection.SynchronizationQueue,
                  ),
                  Visibility(
                    child: IconButton(
                        icon: Icon(Icons.check_box_outline_blank),
                        tooltip: 'برداشتن علامت همه',
                        onPressed: () {
                          if (_activeSection == GActiveFormSection.Profiles) {
                            for (var item in _profiles.items) {
                              setState(() {
                                item.isMarked = false;
                              });
                            }
                          } else {
                            for (var item in _narrations.items) {
                              setState(() {
                                item.isMarked = false;
                              });
                            }
                          }
                        }),
                    visible: _activeSection != GActiveFormSection.Uploads &&
                        _activeSection !=
                            GActiveFormSection.SynchronizationQueue,
                  ),
                  Visibility(
                      child: IconButton(
                        icon: Icon(Icons.delete),
                        tooltip: 'حذف',
                        onPressed: () async {
                          if (_activeSection == GActiveFormSection.Profiles) {
                            await _deleteMarkedProfiles();
                          } else {
                            await _deleteMarkedRecitations();
                          }
                        },
                      ),
                      visible: _activeSection != GActiveFormSection.Uploads &&
                          _activeSection !=
                              GActiveFormSection.SynchronizationQueue),
                  Visibility(
                      child: IconButton(
                        icon: Icon(Icons.publish),
                        tooltip: 'درخواست بررسی',
                        onPressed: () async {
                          var markedNarrations = _narrations.items
                              .where((element) => element.isMarked)
                              .toList();
                          if (markedNarrations.isEmpty) {
                            _key.currentState.showSnackBar(SnackBar(
                              content: Text(
                                  'لطفاً خوانش‌های مد نظر را علامتگذاری کنید.'),
                              backgroundColor: Colors.red,
                            ));
                            return;
                          }
                          String confirmation = markedNarrations.length > 1
                              ? 'آیا از تغییر وضعیت به درخواست بررسی ' +
                                  markedNarrations.length.toString() +
                                  ' خوانش علامتگذاری شده اطمینان دارید؟'
                              : 'آیا از تغییر وضعیت به درخواست بررسی «' +
                                  markedNarrations[0].audioTitle +
                                  '» اطمینان دارید؟';
                          if (await _confirm('تأییدیه', confirmation)) {
                            setState(() {
                              _isLoading = true;
                            });
                            for (var item in markedNarrations) {
                              item.reviewStatus = 1;
                              var updateRes = await RecitationService()
                                  .updateRecitation(item, false);
                              if (updateRes.item2.isNotEmpty) {
                                _key.currentState.showSnackBar(SnackBar(
                                  content: Text('خطا در تغییر وضعیت خوانش ' +
                                      item.audioTitle +
                                      '، اطلاعات بیشتر ' +
                                      updateRes.item2),
                                  backgroundColor: Colors.red,
                                ));
                              }
                              if (updateRes.item1 != null) {
                                setState(() {
                                  _narrations.items.remove(item);
                                });
                              }
                            }
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                      ),
                      visible: _activeSection ==
                              GActiveFormSection.DraftRecitations &&
                          !_canModerate),
                  Visibility(
                      child: IconButton(
                        icon: Icon(Icons.publish),
                        tooltip: 'انتشار',
                        onPressed: () async {
                          var markedNarrations = _narrations.items
                              .where((element) => element.isMarked)
                              .toList();
                          if (markedNarrations.isEmpty) {
                            _key.currentState.showSnackBar(SnackBar(
                              content: Text(
                                  'لطفاً خوانش‌های مد نظر را علامتگذاری کنید.'),
                              backgroundColor: Colors.red,
                            ));
                            return;
                          }
                          String confirmation = markedNarrations.length > 1
                              ? 'آیا از انتشار ' +
                                  markedNarrations.length.toString() +
                                  ' خوانش علامتگذاری شده اطمینان دارید؟'
                              : 'آیا از انتشار «' +
                                  markedNarrations[0].audioTitle +
                                  '» اطمینان دارید؟';
                          if (await _confirm('تأییدیه', confirmation)) {
                            setState(() {
                              _isLoading = true;
                            });
                            for (var item in markedNarrations) {
                              item.reviewStatus = 1;
                              var updateRes = await RecitationService()
                                  .moderateRecitation(
                                      item.id,
                                      RecitationModerationResult.Approve,
                                      '',
                                      false);
                              if (updateRes.item2.isNotEmpty) {
                                _key.currentState.showSnackBar(SnackBar(
                                  content: Text('خطا در تغییر وضعیت خوانش ' +
                                      item.audioTitle +
                                      '، اطلاعات بیشتر ' +
                                      updateRes.item2),
                                  backgroundColor: Colors.red,
                                ));
                              }
                              if (updateRes.item1 != null) {
                                setState(() {
                                  _narrations.items.remove(item);
                                });
                              }
                            }
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                      ),
                      visible: (_activeSection ==
                                  GActiveFormSection.DraftRecitations &&
                              _canModerate) ||
                          _activeSection ==
                              GActiveFormSection.AllUsersPendingRecitations),
                  Visibility(
                    child: IconButton(
                      tooltip: 'انتقال مالکیت',
                      icon: Icon(Icons.transfer_within_a_station),
                      onPressed: () async {
                        await _transferOwnership();
                      },
                    ),
                    visible: _canImport &&
                        _activeSection == GActiveFormSection.Profiles,
                  ),
                  Visibility(
                    child: IconButton(
                        icon: Icon(Icons.people),
                        tooltip: 'انتقال خوانش‌های فریدون فرح‌اندوز',
                        onPressed: () async {
                          if (await _confirm('انتقال به بالا',
                              'از انتقال خوانشهای فریدون فرح‌اندوز به بالا اطمینان دارید؟')) {
                            setState(() {
                              _isLoading = true;
                            });

                            var ret = await RecitationService()
                                .makeFFRecitationsFirst(false);

                            setState(() {
                              _isLoading = false;
                            });

                            if (ret.item2.isNotEmpty) {
                              _key.currentState.showSnackBar(SnackBar(
                                content: Text(ret.item2),
                                backgroundColor: Colors.red,
                              ));
                            } else {
                              _key.currentState.showSnackBar(SnackBar(
                                content: Text(
                                    'تعداد خوانش‌های تحت تأثیر قرار گرفته: ' +
                                        ret.item1.toString()),
                                backgroundColor: Colors.green,
                              ));
                            }
                          }
                        }),
                    visible: _canImport &&
                        _activeSection == GActiveFormSection.Profiles,
                  ),
                  Visibility(
                    child: IconButton(
                      icon: Icon(Icons.upload_file),
                      tooltip: 'تلاش مجدد',
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        var ret = await RecitationService().retryPublish(false);
                        setState(() {
                          _isLoading = false;
                        });
                        if (ret.isNotEmpty) {
                          _key.currentState.showSnackBar(SnackBar(
                            content: Text('خطا در تلاش مجدد: ' + ret),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                    ),
                    visible: _canModerate &&
                        _activeSection ==
                            GActiveFormSection.SynchronizationQueue,
                  ),
                ],
              ),
              drawer: Drawer(
                // Add a ListView to the drawer. This ensures the user can scroll
                // through the options in the drawer if there isn't enough vertical
                // space to fit everything.
                child: ListView(
                  // Important: Remove any padding from the ListView.
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                      child: Column(
                        children: [
                          Text(
                            'سلام ' + _userFrinedlyName,
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text('خوانش‌های پیش‌نویس من'),
                      leading: Icon(Icons.music_note,
                          color: Theme.of(context).primaryColor),
                      selected:
                          _activeSection == GActiveFormSection.DraftRecitations,
                      onTap: () async {
                        if (_activeSection !=
                            GActiveFormSection.DraftRecitations) {
                          setState(() {
                            _narrations.items.clear();
                            _narrationsPageNumber = 1;
                            _activeSection =
                                GActiveFormSection.DraftRecitations;
                          });
                          await _loadData();

                          Navigator.of(context).pop(); //close drawer
                        }
                      },
                    ),
                    ListTile(
                      title: Text('بارگذاری‌های من'),
                      leading: Icon(Icons.upload_file,
                          color: Theme.of(context).primaryColor),
                      selected: _activeSection == GActiveFormSection.Uploads,
                      onTap: () async {
                        if (_activeSection != GActiveFormSection.Uploads) {
                          setState(() {
                            _activeSection = GActiveFormSection.Uploads;
                          });
                          if (_uploads.items.length == 0) {
                            await _loadData();
                          }

                          Navigator.of(context).pop(); //close drawer
                        }
                      },
                    ),
                    ListTile(
                      title: Text('همهٔ خوانش‌های من'),
                      leading: Icon(Icons.music_note,
                          color: Theme.of(context).primaryColor),
                      selected:
                          _activeSection == GActiveFormSection.AllMyRecitations,
                      onTap: () async {
                        if (_activeSection !=
                            GActiveFormSection.AllMyRecitations) {
                          setState(() {
                            _narrationsPageNumber = 1;
                            _narrations.items.clear();
                            _activeSection =
                                GActiveFormSection.AllMyRecitations;
                          });
                          await _loadData();

                          Navigator.of(context).pop(); //close drawer
                        }
                      },
                    ),
                    Visibility(
                        child: ListTile(
                          title: Text('خوانش‌های در انتظار تأیید'),
                          leading: Icon(Icons.music_note,
                              color: Theme.of(context).primaryColor),
                          selected: _activeSection ==
                              GActiveFormSection.AllUsersPendingRecitations,
                          onTap: () async {
                            if (_activeSection !=
                                GActiveFormSection.AllUsersPendingRecitations) {
                              setState(() {
                                _narrationsPageNumber = 1;
                                _narrations.items.clear();
                                _activeSection = GActiveFormSection
                                    .AllUsersPendingRecitations;
                              });
                              await _loadData();

                              Navigator.of(context).pop(); //close drawer
                            }
                          },
                        ),
                        visible: _canModerate),
                    ListTile(
                      title: Text('نمایه‌های من'),
                      leading: Icon(Icons.people,
                          color: Theme.of(context).primaryColor),
                      selected: _activeSection == GActiveFormSection.Profiles,
                      onTap: () async {
                        if (_activeSection != GActiveFormSection.Profiles) {
                          setState(() {
                            _activeSection = GActiveFormSection.Profiles;
                          });
                          if (_profiles.items.length == 0) {
                            await _loadData();
                          }

                          Navigator.of(context).pop(); //close drawer
                        }
                      },
                    ),
                    ListTile(
                      title: Text('صف انتشار در گنجور'),
                      leading: Icon(Icons.send_to_mobile,
                          color: Theme.of(context).primaryColor),
                      selected: _activeSection ==
                          GActiveFormSection.SynchronizationQueue,
                      onTap: () async {
                        if (_activeSection !=
                            GActiveFormSection.SynchronizationQueue) {
                          setState(() {
                            _activeSection =
                                GActiveFormSection.SynchronizationQueue;
                          });
                          if (_profiles.items.length == 0) {
                            await _loadData();
                          }

                          Navigator.of(context).pop(); //close drawer
                        }
                      },
                    ),
                    ListTile(
                      title: Text('مشخصات کاربری'),
                      leading: Icon(Icons.person,
                          color: Theme.of(context).primaryColor),
                      onTap: () async {
                        var url = 'https://museum.ganjoor.net/profile';
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          throw 'خطا در نمایش نشانی $url';
                        }
                        Navigator.of(context).pop(); //close drawer
                      },
                    ),
                    ListTile(
                      title: Text('خروج'),
                      leading: Icon(Icons.logout,
                          color: Theme.of(context).primaryColor),
                      onTap: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        await AuthService().logout();

                        setState(() {
                          _isLoading = false;
                        });

                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginForm()));
                      },
                    ),
                  ],
                ),
              ),
              persistentFooterButtons: [
                Text(currentPageText),
                Visibility(
                    child: IconButton(
                      icon: Icon(Icons.first_page),
                      tooltip: 'اولین صفحه',
                      onPressed: () async {
                        if (_activeSection ==
                                GActiveFormSection.DraftRecitations ||
                            _activeSection ==
                                GActiveFormSection.AllMyRecitations ||
                            _activeSection ==
                                GActiveFormSection.AllUsersPendingRecitations) {
                          _narrationsPageNumber = 1;
                          await _loadData();
                        } else if (_activeSection ==
                            GActiveFormSection.Uploads) {
                          _uploadsPageNumber = 1;
                          await _loadData();
                        }
                      },
                    ),
                    visible: _activeSection != GActiveFormSection.Profiles &&
                        _activeSection !=
                            GActiveFormSection.SynchronizationQueue),
                Visibility(
                    child: IconButton(
                      icon: Icon(Icons.navigate_before),
                      tooltip: 'صفحهٔ قبل',
                      onPressed: () async {
                        if (_activeSection ==
                                GActiveFormSection.DraftRecitations ||
                            _activeSection ==
                                GActiveFormSection.AllMyRecitations ||
                            _activeSection ==
                                GActiveFormSection.AllUsersPendingRecitations) {
                          _narrationsPageNumber =
                              _narrations.paginationMetadata == null
                                  ? 1
                                  : _narrations.paginationMetadata.currentPage -
                                      1;
                          if (_narrationsPageNumber <= 0)
                            _narrationsPageNumber = 1;
                          await _loadData();
                        } else if (_activeSection ==
                            GActiveFormSection.Uploads) {
                          _uploadsPageNumber =
                              _uploads.paginationMetadata == null
                                  ? 1
                                  : _uploads.paginationMetadata.currentPage - 1;
                          if (_uploadsPageNumber <= 0) _uploadsPageNumber = 1;
                          await _loadData();
                        }
                      },
                    ),
                    visible: _activeSection != GActiveFormSection.Profiles &&
                        _activeSection !=
                            GActiveFormSection.SynchronizationQueue),
                Visibility(
                    child: IconButton(
                      icon: Icon(Icons.navigate_next),
                      tooltip: 'صفحهٔ بعد',
                      onPressed: () async {
                        if (_activeSection ==
                                GActiveFormSection.DraftRecitations ||
                            _activeSection ==
                                GActiveFormSection.AllMyRecitations ||
                            _activeSection ==
                                GActiveFormSection.AllUsersPendingRecitations) {
                          _narrationsPageNumber =
                              _narrations.paginationMetadata == null
                                  ? 1
                                  : _narrations.paginationMetadata.currentPage +
                                      1;
                          await _loadData();
                        } else if (_activeSection ==
                            GActiveFormSection.Uploads) {
                          _uploadsPageNumber =
                              _uploads.paginationMetadata == null
                                  ? 1
                                  : _uploads.paginationMetadata.currentPage + 1;
                          await _loadData();
                        }
                      },
                    ),
                    visible: _activeSection != GActiveFormSection.Profiles &&
                        _activeSection !=
                            GActiveFormSection.SynchronizationQueue),
                Visibility(
                    child: IconButton(
                      icon: Icon(Icons.last_page),
                      tooltip: 'صفحهٔ آخر',
                      onPressed: () async {
                        if (_activeSection ==
                                GActiveFormSection.DraftRecitations ||
                            _activeSection ==
                                GActiveFormSection.AllMyRecitations ||
                            _activeSection ==
                                GActiveFormSection.AllUsersPendingRecitations) {
                          _narrationsPageNumber =
                              _narrations.paginationMetadata == null
                                  ? 1
                                  : _narrations.paginationMetadata.totalPages;
                          await _loadData();
                        } else if (_activeSection ==
                            GActiveFormSection.Uploads) {
                          _uploadsPageNumber =
                              _uploads.paginationMetadata == null
                                  ? 1
                                  : _uploads.paginationMetadata.totalPages;
                          await _loadData();
                        }
                      },
                    ),
                    visible: _activeSection != GActiveFormSection.Profiles &&
                        _activeSection !=
                            GActiveFormSection.SynchronizationQueue),
                Visibility(
                    child: IconButton(
                      icon: Icon(Icons.search),
                      tooltip: 'جستجو',
                      onPressed: () async {
                        var res = await _getSearchParams();
                        if (res != null) {
                          setState(() {
                            _pageSize = res.item1;
                            _searchTerm = res.item2;
                          });
                          await _loadData();
                        }
                      },
                    ),
                    visible: _activeSection != GActiveFormSection.Uploads &&
                        _activeSection !=
                            GActiveFormSection.SynchronizationQueue)
              ],
              body: Builder(builder: (context) => Center(child: items)),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  switch (_activeSection) {
                    case GActiveFormSection.DraftRecitations:
                    case GActiveFormSection.AllMyRecitations:
                    case GActiveFormSection.AllUsersPendingRecitations:
                    case GActiveFormSection.Uploads:
                    case GActiveFormSection.SynchronizationQueue:
                      await _newNarrations();
                      if (_activeSection == GActiveFormSection.Uploads) {
                        await _loadData();
                      }
                      break;
                    case GActiveFormSection.Profiles:
                      var result = await _newProfile();
                      if (result != null) {
                        setState(() {
                          _isLoading = true;
                        });
                        var serviceResult =
                            await RecitationService().addProfile(result, false);
                        setState(() {
                          _isLoading = false;
                        });
                        if (serviceResult.item2 == '') {
                          setState(() {
                            if (serviceResult.item1.isDefault) {
                              for (var item in _profiles.items) {
                                item.isDefault = false;
                              }
                            }
                            _profiles.items.insert(0, serviceResult.item1);
                          });
                        } else {
                          _key.currentState.showSnackBar(SnackBar(
                            content: Text(
                                'خطا در ایجاد نمایه: ' + serviceResult.item2),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                      break;
                  }
                },
                child: Icon(Icons.add),
                tooltip: _activeSection == GActiveFormSection.Profiles
                    ? 'ایجاد نمایهٔ جدید'
                    : 'ارسال خوانش‌های جدید',
              ),
            )));
  }
}
