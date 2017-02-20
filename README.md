# BGFMDB
# 重新封装抽取了FMDB,直接存储和读取对象,使用起来超级方便快捷.
##  在自己开发中，每次用到数据库都会纠结是使用CoreData还是FMDB。 CoreData虽然Api简单，但是调用栈非常复杂，要初始化一个Context需要至少20行代码,
## 显然，对于这种这么恶心的情况，我们的大Github必须有人会跳出来解决这种问题。于是就出现了MagicRecord,MMRecod,RestKit等CoreData的封装库。一开
## 始遇到这些库的时候，好用到几乎让我想把所有项目的数据库都换成CoreData了。两句话解决CoreData调用栈的初始化，一句话完成数据库版本升级和自动数据合
## 并更新（虽然我们很少用到.然而这并不能解决一个根本性的问题，CoreData中的每个Object都要和一个context进行绑定，导致我们很多业务需求需要创建自己
## 的私有context，然后再需要更新的时候保存到主context中。这又导致了我们在controller中或者在自己的业务类中维护多一个私有context属性。同时这些库
## 都是外国人写的,很多中初级开发者其实看不太懂英文(或是懒得看),特别是那些特别庞大的库,而且有时候其实只想用其中一小部分的存储功能,所以，最后
## 我选择了FMDB进行封装。
#  以上的话是JRDB的作者说的(最后那几句是我加的😊),也就是网上比较流行的面向对象封装的FMDB,但是JRDB也有缺点,使用也有点麻烦,要对类注册等等乱七八糟
# 的,让初级开发者很懵逼,而且JRDB的对象级别Api没有条件查找,类与类数据之间的拷贝等,所以综合上述,我决定自己进行封装一个傻瓜级存储库,开发者不需要过多
# 的了解,只要对象继承自我的BGManageObject基类就拥有存储功能了,一句API调用搞定,绝对傻瓜级别应用,当然这不是骂使用者傻瓜哈😊,是强调使用特别方便,
# 一看就懂,马马上手使用,废话不多说,看使用Api介绍.
### /**  
### 提示:所有新建的类要继承自该类.(才能使用该库直接存储数据)      
### 1.集合类型目前只支持数组(NSArray及其子类)和字典(NSDictionary及其子类)，     
### 2.数组,字典,类变量中的元素类型目前只支持系统自带的基本类型(int,long,NSString,NSNumber等),NSData暂不支持.     
### 3.对于下面的条件参数where,目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.     
### 4.keypath查询有专门的接口: findAsync:forKeyPath:value:complete:     
### */      
//同步：线程阻塞；异步：线程非阻塞;   
/**   
 设置调试模式   
 @debug YES:打印SQL语句, NO:不打印SQL语句.   
 */   
+(void)setDebug:(BOOL)debug;   
/**   
 同步存储.   
 */   
-(BOOL)save;   
/**   
 @async YES:异步存储,NO:同步存储.   
 */   
-(void)saveAsync:(BOOL)async complete:(Complete_B)complete;   
/**   
 同步查询所有结果.   
 */   
+(NSArray* _Nullable)findAll;   
/**   
 @async YES:异步查询所有结果,NO:同步查询所有结果.   
 */   
+(void)findAllAsync:(BOOL)async complete:(Complete_A)complete;   
/**   
 @async YES:异步查询所有结果,NO:同步查询所有结果.   
 @limit 每次查询限制的条数,0则无限制.   
 @desc YES:降序，NO:升序.   
 */   
+(void)findAllAsync:(BOOL)async limit:(NSInteger)limit orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:   (Complete_A)complete;   
/**   
 @async YES:异步查询所有结果,NO:同步查询所有结果.   
 @range 查询的范围(从location开始的后面length条).   
 @desc YES:降序，NO:升序.   
 */   
+(void)findAllAsync:(BOOL)async range:(NSRange)range orderBy:(NSString* _Nullable)orderBy desc:(BOOL)desc complete:(Complete_A)complete;   
/**   
 @async YES:异步查询所有结果,NO:同步查询所有结果.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即查询name=标哥,age=>25的数据;   
 可以为nil,为nil时查询所有数据;   
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.   
 */   
+(void)findAsync:(BOOL)async where:(NSArray* _Nullable)where complete:(Complete_A)complete;   
/**   
 keyPath查询   
 @async YES:异步查询所有结果,NO:同步查询所有结果.   
 @keyPath 形式 @"user.student.name".   
 @value 值,形式 @“小芳”   
 说明: 即查询 user.student.name=小芳的对象数据 (用于嵌套的自定义类)   
 */   
+(void)findAsync:(BOOL)async forKeyPath:(NSString* _Nonnull)keyPath value:(id _Nonnull)value complete:(Complete_A)complete;
/**   
 同步更新数据.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;   
 可以为nil,nil时更新所有数据;   
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.   
 */   
-(BOOL)updateWhere:(NSArray* _Nullable)where;   
/**   
 @async YES:异步更新,NO:同步更新.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即更新name=标哥,age=>25的数据;   
 可以为nil,nil时更新所有数据;   
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持.   
 */   
-(void)updateAsync:(BOOL)async where:(NSArray* _Nullable)where complete:(Complete_B)complete;   
/**   
 同步删除数据.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.   
 不可以为nil;   
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持   
 */   
+(BOOL)deleteWhere:(NSArray* _Nonnull)where;   
/**   
 @async YES:异步删除,NO:同步删除.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即删除name=标哥,age=>25的数据.   
 不可以为nil;   
 目前不支持keypath的key,即嵌套的自定义类, 形式如@[@"user.name",@"=",@"习大大"]暂不支持   
 */   
+(void)deleteAsync:(BOOL)async where:(NSArray* _Nonnull)where complete:(Complete_B)complete;   
/**   
 同步清除所有数据   
 */   
+(BOOL)clear;   
/**   
 @async YES:异步清除所有数据,NO:同步清除所有数据.   
 */   
+(void)clearAsync:(BOOL)async complete:(Complete_B)complete;   
/**   
 同步删除这个类的数据表   
 */   
+(BOOL)drop;   
/**   
 @async YES:异步删除这个类的数据表,NO:同步删除这个类的数据表.   
 */   
+(void)dropAsync:(BOOL)async complete:(Complete_B)complete;   
/**   
 查询该表中有多少条数据   
 @name 表名称.   
 @where 条件数组，形式@[@"name",@"=",@"标哥",@"age",@"=>",@(25)],即name=标哥,age=>25的数据有多少条,为nil时返回全部数据的条数.   
 */   
+(NSInteger)countWhere:(NSArray* _Nullable)where;   
/**   
 刷新,当类变量名称改变时,调用此接口刷新一下.   
 @async YES:异步刷新,NO:同步刷新.   
 */   
+(void)refreshAsync:(BOOL)async complete:(Complete_I)complete;   
/**   
 将某表的数据拷贝给另一个表   
 @async YES:异步复制,NO:同步复制.   
 @destCla 目标类.   
 @keyDict 拷贝的对应key集合,形式@{@"srcKey1":@"destKey1",@"srcKey2":@"destKey2"},即将源类srcCla中的变量值拷贝给目标类destCla中的变量destKey1，srcKey2和destKey2同理对应,以此推类.   
 @append YES: 不会覆盖destCla的原数据,在其末尾继续添加；NO: 覆盖掉destCla原数据,即将原数据删掉,然后将新数据拷贝过来.   
 */   
+(void)copyAsync:(BOOL)async toClass:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete;   
