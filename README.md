# BGFMDB让数据的增删改查分别只需要一行代码即可,就是这么简单任性.
## 最新更新:
`上个版本更新:`     
1.修复了之前存储父类变量为空的bug,同时加入了"字典转模型"和"模型转字典"的功能,在只需要将服务器传过来的字典转成模型的情况下,可以不必要再引入MJExtension那么多文件,造成代码冗余,缩减安装包.      
2.快速实现一句代码"字典转模型",一句代码"存储数据",是不是相当爽歪歪!!!       
`现版本更新:`         
1.加入了线程安全操作.    
2.部分代码块加入了自动释放池,防止查询数据量巨大时内存溢出.       
3.类数据库更新和类之间数据拷贝加入了事务操作.   
## 小伙伴们的使用反馈   
[![BGFMDB](http://o7pq80nc2.bkt.clouddn.com/showUse.png)
[BGFMDB](http://o7pq80nc2.bkt.clouddn.com/showUseThumbnail.jpg "小伙伴们的使用反馈")
[![BGFMDB1](http://o7pq80nc2.bkt.clouddn.com/showUse1.png)
[BGFMDB1](http://o7pq80nc2.bkt.clouddn.com/showUse1Thumbnail.jpg "小伙伴们的使用反馈")
## 作者联系方式:       
QQ: 450426721   
QQ邮箱: 450426721@qq.com   
使用交流QQ群: 572359447    
如果在使用过程中发现什么问题或有什么疑问,请加我QQ反馈.    
## 完美支持:    
int,long,signed,float,double,NSInteger,CGFloat,BOOL,NSString,NSMutableString,NSNumber,NSArray,NSMutableArray,NSDictionary,NSMutableDictionary,NSMapTable,NSHashTable,NSData,NSMutableData,UIImage,NSDate,NSURL,NSRange,CGRect,CGSize,CGPoint,自定义对象 等的存储.   
## 写本库的动机: 在对coredata和realm做了探究总结后,发现了很多有缺陷的地方,最明显的就是下面的原因:   
### realm缺陷: 
Realm不支持集合类型,这一点也是比较蛋疼。   
Realm支持以下的属性类型：BOOL、bool、int、NSInteger、long、long long、float、double、NSString、NSDate、NSData以及 被特殊类型标记的NSNumber。CGFloat属性的支持被取消了，因为它不具备平台独立性。    
这里就是不支持集合，比如说NSArray，NSMutableArray，NSDictionary，NSMutableDictionary，NSSet，NSMutableSet。如果服务器传来的一个字典，key是一个字符串，对应的value就是一个数组，这时候就想存储这个数组就比较困难了。   
### coredata缺陷:   
coredata虽然通过Transformable可以存取集合类型,但需要开发者去进行转换处理,使用起来不方便直观,虽然coredata有很多好用的封装库,像ResKit,MMRecord等,但这些库比较庞大,而且都是英文介绍,不利于国内初中级开发的快速开发使用.    
## 虽然国内也已经有了对FMDB面相对象层的封装,比如像JRDB,LKDBHelper等,但是在使用总结后还是发现不少的问题,问题如下:    
JRDB存储数组需要传入对象的泛型,同时还要复写一些函数和映射，这对于初中级开发者是很不利的,看的很萌逼.    
LKDBHelper好一点,但也要复写不少的函数,而且LKDBHelper的使用demo有点乱,还有就是不支持NSMaptable,NSHashTable的存储,LKDBHelper还有一个致命的弱点就是当类变量名称跟sqlite的关键字一样时,会发生冲突错误！  
### 而最重要的是: JRDB,LKDBHelper都不支持同一数组中存储不同类型的自定义类型数据,BGFMDB则完美支持,JRDB,LKDBHelper已经成为过去,现在是BGFMDB的时代,作者的宣言是：“要把BGFMDB写成不会写代码的人都会用的库”，欢迎大家反馈和吐槽问题,骚年作者等着你们.
## 综合上述原因后,我决定写一款适合国内初中级开发者使用的存储封装库(BGFMDB),不管是从使用步骤还是支持的存储类型上,都比JRDB,LKDB简单好用和全面.    
## 本库几乎支持存储ios所有基本的自带数据类型.    
## 使用介绍(喜欢的话别忘了给本库一个Star😊).   
## CocoaPods的方式.
### Podfile
```Podfile
platform :ios, '8.0'

target '工程名称' do
pod ‘BGFMDB’, '~> 1.15’
end
```
## 直接下载库代码使用方式.
### 添加所需依赖库   
libsqlite3   
### 导入头文件   
```Objective-C
/**
只要在自己的类中导入了NSObject+BGModel.h这个头文件,本类就具有了存储功能.
*/
#import <Foundation/Foundation.h>
#import "NSObject+BGModel.h"
@interface stockModel : NSObject
@property(nonatomic,copy)NSString* name;
@property(nonatomic,strong)NSNumber* stockData;
+(instancetype)stockWithName:(NSString*)name stockData:(NSNumber*)stockData;
@end
```
### 主键
```Objective-C
/**
本库自带的自动增长主键.
*/
@property(nonatomic,strong)NSNumber*_Nullable ID;
```
### 唯一约束
```Objective-C
/**
如果需要指定“唯一约束”字段,就复写该函数,这里指定 name 为“唯一约束”.
*/
-(NSString *)uniqueKey{
    return @"name";
}
```
### 初始化对象
```Objective-C
People* p = [self people];
```
### 存储
```Objective-C
/**
同步存储.
*/
[p save];

/**
异步存储.
*/
[p saveAsync:^(BOOL isSuccess) {
       //you code
   }];
   
/**
覆盖掉原来People类的所有数据,只存储当前对象的数据.
*/
[p cover];

/**
 忽略存储，即忽略掉 user,info,students 这三个变量不存储.
 */
[p saveIgnoredKeys:@[@"user",@"info",@"students"]];
```
### 查询
```Objective-C
/**
同步查询所有People的数据.
*/
NSArray* finfAlls = [People findAll];

/**
异步查询所有People的数据.
*/
[People findAllAsync:^(NSArray * _Nullable array) {
        // you code
    }];
    
/**
异步查询People类的数据,查询限制3条,通过age降序排列.
*/
[People findAllAsyncWithLimit:3 orderBy:@"age" desc:YES complete:^(NSArray * _Nullable array) {
    for(People* p in array){
      // you code
    }
}];

/**
异步查询People类的数据,查询范围从第10处开始的后面5条,不排序.
*/
[People findAllAsyncWithRange:NSMakeRange(10,5) orderBy:nil desc:NO complete:^(NSArray * _Nullable array) {
     for(People* p in array){
        // you code
     }
}];

/**
查询name等于爸爸和age等于45,或者name等于马哥的数据.  此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
*/
NSArray* arrayConds1 = [People findFormatSqlConditions:@"where %@=%@ and %@=%@ or %@=%@",sqlKey(@"age"),sqlValue(@(45)),sqlKey(@"name"),sqlValue(@"爸爸"),sqlKey(@"name"),sqlValue(@"马哥")];

/**
查询user.student.human.body等于小芳 和 user1.name中包含fuck这个字符串的数据.
*/
NSArray* arrayConds2 = [People findFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"])];

/**
查询user.student.human.body等于小芳,user1.name中包含fuck这个字符串 和 name等于爸爸的数据.
*/
NSArray* arrayConds3 = [People findFormatSqlConditions:@"where %@ and %@=%@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳",@"user1.name",Contains,@"fuck"]),sqlKey(@"name"),sqlValue(@"爸爸")];
```
### 更新
```Objective-C
/**
将People类数据中name=@"标哥"，num=220.88的数据更新为当前对象的数据.
*/
[p updateWhere:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)]];

/**
将People类中name等于"马云爸爸"的数据的name更新为"马化腾",此接口是为了方便开发者自由扩展更深层次的更新条件逻辑.
*/
[People updateFormatSqlConditions:@"set %@=%@ where %@=%@",sqlKey(@"name"),sqlValue(@"马化腾"),sqlKey(@"name"),sqlValue(@"马云爸爸")];

/**
将People类数据中name等于"马化腾"的数据更新为当前对象的数据.
*/
[p updateFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"爸爸")];
```
### 删除
```Objective-C
/**
同步删除People类数据中name=@"标哥"，num=220.88的数据.
*/
[People deleteWhere:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)]];

/**
异步删除People类数据中name=@"标哥"，num=220.88的数据.
*/
[People deleteAsync:@[@"name",@"=",@"标哥",@"num",@"=",@(220.88)] complete:^(BOOL isSuccess) {
      // you code  
}];

/**
清除People表的所有数据.
*/
[People clear];

/**
删除People的数据库表.
*/
[People drop];

/**
删除People类中name等于"美国队长"的数据,此接口是为了方便开发者自由扩展更深层次的删除条件逻辑.
*/
[People deleteFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];

/**
删除People类中user.student.human.body等于"小芳"的数据
*/
[People deleteFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];

/**
删除People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据
*/
[People deleteFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
```
### keyPath(类嵌套的时候使用)   
```Objective-C
@interface Human : NSObject
@property(nonatomic,copy)NSString* sex;
@end

@interface Student : NSObject
@property(nonatomic,strong)Human* human;
@end

@interface User : NSObject
@property(nonatomic,strong)Student* student;
@end

@interface People : NSObject
@property(nonatomic,strong)User* user1;
@property(nonatomic,strong)User* user2;
@end

/**
查询People类中user2.student.human.sex中等于@“女”的数据.
*/
[People findForKeyPathAndValues:@[@"user2.student.human.sex",Equal,@"女"]];

/**
将People类中user1.name包含@“小明”字符串 和 user2.student.human.sex中等于@“女”的数据 更新为当前对象的数据.
*/
[p updateForKeyPathAndValues:@[@"user1.name",Contains,@"小明",@"user2.student.human.sex",Equal,@"女"]];
 
/**
删除People类中user1.name包含@“小明”字符串的数据.
*/
[People deleteForKeyPathAndValues:@[@"user1.name",Contains,@"小明"]];
```
### 获取类数据库版本
```Objective-C
/**
 获取该类的数据库版本号;
*/
NSInteger version = [People version];
```
### 类数据库版本升级
```Objective-C
//注: 版本号从1开始,依次往后递增,本次更新版本号不得 低于或等于 上次的版本号,否则不会更新.
/**
 如果类'变量名'或'唯一约束'发生改变,则调用此API刷新该类数据库,不需要新旧映射的情况下使用此API.
*/
[People updateVersion:version];

/**
如果类'变量名'或'唯一约束'发生改变,则调用此API刷新该类数据库.data2是新变量名,data是旧变量名,即将旧的值映射到新的变量名,其他不变的变量名会自动复制,只管写出变化的对应映射即可.
*/
[People updateVersion:version keyDict:@{@"data2":@"data"}];
```
### 事务操作
```Objective-C
/**
事务操作,返回YES提交事务,返回NO则回滚事务.
*/
[NSObject inTransaction:^BOOL{
       [p save];//存储
       [p save];
       return NO;
}];
```
### 快速查询数据条数
```Objective-C
/**
查询People类中所有数据的条数.
*/
NSInteger count = [People countWhere:nil]

/**
查询People类中age>=21,name=@"马哥"的数据条数.
*/
NSInteger count = [People countWhere:@[@"age",@">=",@(21),@"name",@"=",@"马哥"]];

/**
查询People类中name等于"美国队长"的数据条数,此接口是为了方便开发者自由扩展更深层次的查询条件逻辑.
*/
NSInteger count = [People countFormatSqlConditions:@"where %@=%@",sqlKey(@"name"),sqlValue(@"美国队长")];

/**
查询People类中user.student.human.body等于"小芳"的数据条数.
 */
NSInteger count = [People countFormatSqlConditions:@"where %@",keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];

/**
查询People类中name等于"美国队长" 和 user.student.human.body等于"小芳"的数据条数.
*/
NSInteger count = [People countFormatSqlConditions:@"where %@=%@ and %@",sqlKey(@"name"),sqlValue(@"美国队长"),keyPathValues(@[@"user.student.human.body",Equal,@"小芳"])];
```
### 类数据之间的拷贝
```Objective-C
/**
 将People的name拷贝给Man的Man_name，其他同理.
 */
 [People copyToClass:[Man class] keyDict:@{@"name":@"Man_name",
                                           @"num":@"Man_num",
                                           @"age":@"Man_age",
                                           @"image":@"image"}
                                           append:NO];
```
### 注册数据变化监听
```Objective-C
/**
注册stockModel类数据变化监听.  
*/
[stockModel registerChangeWithName:@"stockModel" block:^(changeState result){  
        switch (result) {  
            case Insert:  
                NSLog(@"有数据插入");  
                break;  
            case Update:  
                NSLog(@"有数据更新");  
                break;  
            case Delete:  
                NSLog(@"有数据删删除");  
                break;  
            case Drop:  
                NSLog(@"有表删除");  
                break;  
            default:  
                break;  
        }  
    }];  
```
### 移除数据监听
```Objective-C
/**
移除stockModel类数据变化的监听.  
*/
[stockModel removeChangeWithName:@"stockModel"];
```
### 字典转模型
```Objective-C
NSDictionary* dictAni = [self getDogDict];
/**
一代码搞定字典转模型.
*/
Dog* dog = [Dog bg_objectWithKeyValues:dictAni];

NSDictionary* dictMy = [self getMyDict];
/**
一代码搞定字典转模型.
*/
My* my = [My bg_objectWithDictionary:dictMy];
```
### 模型转字典
```Objective-C
/**
一句代码搞定模型转字典.
*/
 NSDictionary* dictBodyAll = [body bj_keyValuesIgnoredKeys:nil];
 
/**
忽略掉hand这个变量不转.
*/
NSDictionary* dictBody = [body bj_keyValuesIgnoredKeys:@[@"hand"]];
```
### 如果模型中的数组变量存储的是自定义类,则需要实现下面的这个函数:
```Objective-C
/**
如果模型中有数组且存放的是自定义的类(NSString等系统自带的类型就不必要了),那就实现该函数,key是数组名称,value是自定的类Class,用法跟MJExtension一样.
*/
-(NSDictionary *)objectClassInArray{
    return @{@"dogs":[Dog class],@"bodys":[Body class]};
}
```
### 基本的使用
```Objective-C
stockModel* shenStock = [stockModel stockWithName:@"深市" stockData:_shenData];   
[shenStock save];//一句代码搞定存储.   
[shenStock updateWhere:@[@"name",@"=",@"深市"]];//一句代码搞定更新.   
NSArray* array = [stockModel findAll];//一句代码搞定查询.   
[stockModel deleteWhere:@[@"name",@"=",@"深市"]];//一句代码搞定删.  
//注册数据变化监听.  
[stockModel registerChangeWithName:@"stockModel" block:^(changeState result){  
        switch (result) {  
            case Insert:  
                NSLog(@"有数据插入");  
                break;  
            case Update:  
                NSLog(@"有数据更新");  
                break;  
            case Delete:  
                NSLog(@"有数据删删除");  
                break;  
            case Drop:  
                NSLog(@"有表删除");  
                break;  
            default:  
                break;  
        }  
    }];  
  //移除数据变化监听.  
 [stockModel removeChangeWithName:@"stockModel"]; 
 
 //更多功能请下载demo使用了解.
```   
### 更多功能请下载demo运行了解使用.   
