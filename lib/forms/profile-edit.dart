import 'package:flutter/material.dart';
import 'package:gaudiopanel/models/recitation/user-recitation-profile-viewmodel.dart';

class ProfileEdit extends StatefulWidget {
  final UserRecitationProfileViewModel profile;

  const ProfileEdit({Key key, this.profile}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProfileEditState(this.profile);
}

class _ProfileEditState extends State<ProfileEdit> {
  final UserRecitationProfileViewModel profile;

  _ProfileEditState(this.profile);

  TextEditingController _nameController = TextEditingController();
  TextEditingController _artistNameController = TextEditingController();
  TextEditingController _artistUrlController = TextEditingController();
  TextEditingController _audioSrcController = TextEditingController();
  TextEditingController _audioSrcUrlController = TextEditingController();
  TextEditingController _fileSuffixWithoutDashController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _artistNameController.dispose();
    _artistUrlController.dispose();
    _audioSrcController.dispose();
    _audioSrcUrlController.dispose();
    _fileSuffixWithoutDashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _nameController.text = this.profile.name;
    _artistNameController.text = this.profile.artistName;
    _artistUrlController.text = this.profile.artistUrl;
    _audioSrcController.text = this.profile.audioSrc;
    _audioSrcUrlController.text = this.profile.audioSrcUrl;
    _fileSuffixWithoutDashController.text = this.profile.fileSuffixWithoutDash;
    return FocusTraversalGroup(
        child: Form(
            autovalidateMode: AutovalidateMode.always,
            child: Wrap(children: [
              Visibility(
                  child: Text(
                      'ویرایش نمایه‌ها روی خوانش‌های موجود تأثیر نمی‌گذارد و لازم است در صورت نیاز آنها را روی خوانش‌های موجود اعمال کنید'),
                  visible: profile.id != null),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'نام نمایه',
                    hintText: 'نام نمایه',
                  ),
                ),
              ),
              Text(
                  'نام نمایه روی خوانش‌ها تأثیر نمی‌گذارد و فقط به انتخاب آسان نمایه در هنگام بارگذاری خوانش‌های جدید کمک می‌کند'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                    controller: _artistNameController,
                    decoration: InputDecoration(
                      labelText: 'نام خوانشگر',
                      hintText: 'نام خوانشگر را با حروف فارسی وارد کنید',
                    )),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextFormField(
                        controller: _artistUrlController,
                        decoration: InputDecoration(
                          labelText: 'نشانی وب',
                          hintText: 'نشانی وب',
                        ))),
              ),
              Text(
                  'نشانی سایت یا کانال تلگرام یا صفحهٔ اینستاگرام، نشانی‌های نامرتبط تبلیغاتی قابل پذیرش نیستند'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                    controller: _audioSrcController,
                    decoration: InputDecoration(
                      labelText: 'نام منبع',
                      hintText: 'نام منبع',
                    )),
              ),
              Text(
                  'اختیاری، اگر خوانش را با کسب اجازه از جای دیگری دریافت و همگام کرده‌اید می‌توانید نام منبع را اینجا وارد کنید'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextFormField(
                        controller: _audioSrcUrlController,
                        decoration: InputDecoration(
                          labelText: 'نشانی وب منبع',
                          hintText: 'نشانی وب منبع',
                        ))),
              ),
              Text(
                  'اختیاری، اگر خوانش را با کسب اجازه از جای دیگری دریافت و همگام کرده‌اید می‌توانید نشانی منبع را اینجا وارد کنید'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextFormField(
                        controller: _fileSuffixWithoutDashController,
                        decoration: InputDecoration(
                          labelText: 'پسوند یکتاساز فایل',
                          hintText: 'پسوند یکتاساز فایل',
                        ))),
              ),
              Text(
                  'نام فایل خوانش شما روی سرور ترکیبی از یک عدد، یک خط میانه (دش) و این حروف خواهد بود. می‌توانید حروف ابتدایی نام و نام خانوادگیتان را به انگلیسی وارد کنید. اگر فایلی همنام فایل نهایی از پیش وجود داشته باشد اعدادی به نام فایل اضافه می‌شود. بهتر است تا حد ممکن این پسوند یکتا باشد'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('پیش‌فرض'),
                      Switch(
                          value: profile.isDefault,
                          onChanged: (value) {
                            setState(() {
                              profile.isDefault = value;
                            });
                          })
                    ]),
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ButtonBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        child: Text(
                            profile.id == '00000000-0000-0000-0000-000000000000'
                                ? 'ایجاد'
                                : 'ذخیره'),
                        onPressed: () {
                          profile.name = _nameController.text;
                          profile.artistName = _artistNameController.text;
                          profile.artistUrl = _artistUrlController.text;
                          profile.audioSrc = _audioSrcController.text;
                          profile.audioSrcUrl = _audioSrcUrlController.text;
                          profile.fileSuffixWithoutDash =
                              _fileSuffixWithoutDashController.text;
                          Navigator.of(context).pop(profile);
                        },
                      ),
                      TextButton(
                        child: Text('انصراف'),
                        onPressed: () {
                          Navigator.of(context).pop(null);
                        },
                      )
                    ],
                  )),
            ])));
  }
}
