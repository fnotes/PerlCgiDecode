# CgiDecode
Perl用のCGIデコード。PHP風にデータを扱えるようにします。

    require 'CgiDecode.pm';
    our(%_GET,%_POST,%_COOKIE,@_FILES);
---
+ ファイルは一時ファイルとして/tmp/に保存されます
+ @_FILES にはファイル情報のみが入っています
+ ファイルはチェック後、移動してください
---
    my $id = 1;
    my $ext = '.csv';

    foreach(@_FILES){

        # $_->{'name'} form name
        # $_->{'type'} file type
        # $_->{'up_name'} upload file name
        # $_->{'tmp_name'} /tmp/*****
        my $f = $q->move($_, ($id++).$ext);
    }

---
さらに詳しくは下記に掲載しています  
https://code-notes.com/lesson/19
---
This software is released under the MIT License, see LICENSE.txt.
