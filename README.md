# BGFMDB算法全新震撼升级.            
# 完美支持:    
# int,long,signed,float,double,NSInteger,CGFloat,BOOL,NSString,NSMutableString,NSNumber,NSArray,NSMutableArray,NSDictionary,NSMutableDictionary,NSMapTable,NSHashTable,NSData,NSMutableData,UIImage,NSDate,NSURL,NSRange,CGRect,CGSize,CGPoint,自定义对象 等的存储.   
## 写本库的动机: 在对coredata和realm做了探究总结后,发现了很多有缺陷的地方,最明显的就是下面的原因:   
### realm缺陷: 
Realm不支持集合类型,这一点也是比较蛋疼。   
Realm支持以下的属性类型：BOOL、bool、int、NSInteger、long、long long、float、double、NSString、NSDate、NSData以及 被特殊类型标记的NSNumber。CGFloat属性的支持被取消了，因为它不具备平台独立性。   
这里就是不支持集合，比如说NSArray，NSMutableArray，NSDictionary，NSMutableDictionary，NSSet，NSMutableSet。如果服务器传来的一个字典，key是一个字符串，对应的value就是一个数组，这时候就想存储这个数组就比较困难了。   
### coredata缺陷:
coredata虽然通过Transformable可以存取集合类型,但需要开发者去进行转换处理,使用起来不方便直观,虽然coredata有很多好用的封装库,像ResKit,MMRecord等,但这些库比较庞大,而且都是英文介绍,不利于国内初中级开发的快速开发使用.   
## 虽然国内也已经有了对FMDB面相对象层的封装,比如像JRDB,LKDBHelper等,但是在使用总结后还是发现不少的问题,问题如下:   
JRDB存储数组需要传入对象的泛型,同时还要复写一些函数和映射，这对于初中级开发者是很不利的,看的很萌逼.   
LKDBHelper好一点,但也要复写不少的函数,而且LKDBHelper的使用demo有点乱,还有就是不支持NSMaptable,NSHashTable的存储.   
## 综合上述原因后,我决定写一款适合国内初中级开发这使用的封装库(BGFMDB),不管是从使用步骤还是支持的存储类型上,都比JRDB,LKDB简单好用和全面.   
## 本库几乎支持存储ios所有基本的自带数据类型.    
## 一看就懂,马马上手使用,废话不多说,看使用Api介绍.      
               
//同步：线程阻塞；异步：线程非阻塞;   
@property(nonatomic,strong)NSNumber*_Nullable ID;//本库自带的自动增长主键.  
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
 异步存储.   
 */   
-(void)saveAsync:(Complete_B)complete;   
/**   
 同步查询所有结果.   
 */   
+(NSArray* _Nullable)findAll;   
/**   
 异步查询所有结果.   
 */   
+(void)findAllAsync:(Complete_A)complete;   
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
