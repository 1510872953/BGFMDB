//
//  BGFMDB.m
//  BGFMDB
//
//  Created by huangzhibiao on 16/4/28.
//  Copyright © 2016年 Biao. All rights reserved.
//


#import "BGFMDB.h"
#import "FMDB.h"

#define debug(sql) if(self.debug){NSLog(@"SQL语句: %@",sql);}

@interface BGFMDB()

@property (nonatomic, strong) FMDatabaseQueue *queue;

@end

static BGFMDB* BGFmdb;

@implementation BGFMDB

-(void)dealloc{
    if (self.queue) {
        [self.queue close];//关闭数据库
        self.queue = nil;
    }
}

-(instancetype)init{
    self = [super init];
    if (self) {
        // 0.获得沙盒中的数据库文件名
        NSString *filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:SQLITE_NAME];
        // 1.创建数据库队列
        self.queue = [FMDatabaseQueue databaseQueueWithPath:filename];
        //NSLog(@"数据库初始化-----");
    }
    return self;
}

/**
 获取单例函数.
 */
+(_Nonnull instancetype)shareManager{
    if(BGFmdb == nil){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            BGFmdb = [[BGFMDB alloc] init];
        });
    }
    return BGFmdb;
}

/**
 数据库中是否存在表.
 */
-(void)isExistWithTableName:(NSString* _Nonnull)name complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db){
        result = [db tableExists:name];
    }];
    if (complete) {
        complete(result);
    }
}


/**
 创建表(如果存在则不创建).
 */
-(void)createTableWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nonnull)keys uniqueKey:(NSString* _Nullable)uniqueKey complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keys,@"字段数组不能为空!");
    //创表
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db){
        NSString* header = [NSString stringWithFormat:@"create table if not exists %@ (",name];
        NSMutableString* sql = [[NSMutableString alloc] init];
        [sql appendString:header];
        BOOL uniqueKeyFlag = NO;
        for(int i=0;i<keys.count;i++){
            
            if(uniqueKey){
                if([BGTool isUniqueKey:uniqueKey with:keys[i]]){
                    uniqueKeyFlag = YES;
                    [sql appendFormat:@"%@ unique",[BGTool keyAndType:keys[i]]];
                }else if ([[keys[i] componentsSeparatedByString:@"*"][0] isEqualToString:@"ID"]){
                    [sql appendFormat:@"%@ primary key autoincrement",[BGTool keyAndType:keys[i]]];
                }else{
                    [sql appendString:[BGTool keyAndType:keys[i]]];
                }
            }else{
                if ([[keys[i] componentsSeparatedByString:@"*"][0] isEqualToString:@"ID"]){
                    [sql appendFormat:@"%@ primary key autoincrement",[BGTool keyAndType:keys[i]]];
                }else{
                    [sql appendString:[BGTool keyAndType:keys[i]]];
                }
            }
            
            if (i == (keys.count-1)) {
                [sql appendString:@");"];
            }else{
                [sql appendString:@","];
            }
        }
        
        if(uniqueKey){
            NSAssert(uniqueKeyFlag,@"没有找到设置的主键,请检查primarykey返回值是否正确!");
        }
        debug(sql);
        result = [db executeUpdate:sql];
    }];
    if (complete){
        complete(result);
    }
}
/**
 插入数据.
 */
-(void)insertIntoTableName:(NSString* _Nonnull)name Dict:(NSDictionary* _Nonnull)dict complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(dict,@"插入值字典不能为空!");
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSArray* keys = dict.allKeys;
        NSArray* values = dict.allValues;
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"insert into %@(",name];
        for(int i=0;i<keys.count;i++){
            [SQL appendFormat:@"%@",keys[i]];
            if(i == (keys.count-1)){
                [SQL appendString:@") "];
            }else{
                [SQL appendString:@","];
            }
        }
        [SQL appendString:@"values("];
        for(int i=0;i<values.count;i++){
            [SQL appendString:@"?"];
            if(i == (keys.count-1)){
                [SQL appendString:@");"];
            }else{
                [SQL appendString:@","];
            }
        }
        
        debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:values];
    }];
    if (complete) {
        complete(result);
    }
}
/**
 根据条件查询字段.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(Complete_A)complete{
    NSAssert(name,@"表名不能为空!");
    __block NSMutableArray* arrM = [[NSMutableArray alloc] init];
    __block NSArray* arguments;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendString:@"select"];
        if ((keys!=nil)&&(keys.count>0)) {
            [SQL appendString:@" "];
            for(int i=0;i<keys.count;i++){
                [SQL appendFormat:@"%@%@",BG,keys[i]];
                if (i != (keys.count-1)) {
                    [SQL appendString:@","];
                }
            }
        }else{
            [SQL appendString:@" *"]; 
        }
        [SQL appendFormat:@" from %@",name];
        
        if((where!=nil) && (where.count>0)){
            NSArray* results = [BGTool where:where];
            [SQL appendString:results[0]];
            arguments = results[1];
        }
        
        debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL withArgumentsInArray:arguments];
        NSAssert(rs,@"查询错误,可能是 类变量名 发生了改变或 字段 不存在!,请存储后再读取,或检查条件数组 字段名称 是否正确");
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
    }];
    
    if (complete) {
        complete(arrM);
    }
    //NSLog(@"查询 -- %@",arrM);
}

/**
 查询对象.
 */
-(void)queryWithTableName:(NSString* _Nonnull)name param:(NSString* _Nullable)param where:(NSArray* _Nullable)where complete:(Complete_A)complete{
    NSAssert(name,@"表名不能为空!");
    __block NSMutableArray* arrM = [[NSMutableArray alloc] init];
    __block NSArray* arguments;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSMutableString* SQL = [NSMutableString string];
        [SQL appendFormat:@"select * from %@",name];
        
        if ((where!=nil) && (where.count>0)){
            if((where!=nil) && (where.count>0)){
                NSArray* results = [BGTool where:where];
                [SQL appendString:results[0]];
                arguments = results[1];
            }
        }
        
        !param?:[SQL appendFormat:@" %@",param];
        debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL withArgumentsInArray:arguments];
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
    }];
    
    if (complete) {
        complete(arrM);
    }
    //NSLog(@"查询 -- %@",arrM);
}

-(void)queryWithTableName:(NSString* _Nonnull)name forKeyPath:(NSString* _Nonnull)keyPath value:(id _Nonnull)value complete:(Complete_A)complete{
    NSAssert([keyPath containsString:@"."], @"keyPath错误,正确形式如: user.stident.name");
    NSAssert(value,@"值不能为空!");
    NSArray* keypaths = [keyPath componentsSeparatedByString:@"."];
    NSMutableString* keyPathParam = [NSMutableString string];
    for(int i=1;i<keypaths.count;i++){
        i!=1?:[keyPathParam appendString:@"%"];
        [keyPathParam appendFormat:@"%@",keypaths[i]];
        [keyPathParam appendString:@"%"];
    }
    [keyPathParam appendFormat:@"%@",value];
    [keyPathParam appendString:@"%"];
    __block NSMutableArray* arrM = [[NSMutableArray alloc] init];
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* SQL = [NSString stringWithFormat:@"select * from People where %@%@ like '%@'",BG,keypaths[0],keyPathParam];
        debug(SQL);
        // 1.查询数据
        FMResultSet *rs = [db executeQuery:SQL];
        // 2.遍历结果集
        while (rs.next) {
            NSMutableDictionary* dictM = [[NSMutableDictionary alloc] init];
            for (int i=0;i<[[[rs columnNameToIndexMap] allKeys] count];i++) {
                dictM[[rs columnNameForIndex:i]] = [rs objectForColumnIndex:i];
            }
            [arrM addObject:dictM];
        }
    }];
    
    if (complete) {
        complete(arrM);
    }
}

/**
 更新数据.
 */
-(void)updateWithTableName:(NSString* _Nonnull)name valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    
    __block BOOL result;
    __block NSMutableArray* arguments = [NSMutableArray array];
    [self.queue inDatabase:^(FMDatabase *db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"update %@ set ",name];
        for(int i=0;i<valueDict.allKeys.count;i++){
            [SQL appendFormat:@"%@=?",valueDict.allKeys[i]];
            [arguments addObject:valueDict[valueDict.allKeys[i]]];
            if (i != (valueDict.allKeys.count-1)) {
                [SQL appendString:@","];
            }
        }
        if ((where!=nil) && (where.count>0)){
            if((where!=nil) && (where.count>0)){
                NSArray* results = [BGTool where:where];
                [SQL appendString:results[0]];
                [arguments addObjectsFromArray:results[1]];
            }
        }
        debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
        //NSLog(@"更新:  %@",SQL);
    }];
    
    if (complete) {
        complete(result);
    }
}

/**
 根据条件删除数据.
 */
-(void)deleteWithTableName:(NSString* _Nonnull)name where:(NSArray* _Nonnull)where complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(where,@"条件数组错误! 不能为空");
    __block BOOL result;
    __block NSMutableArray* arguments = [NSMutableArray array];
    [self.queue inDatabase:^(FMDatabase *db) {
        NSMutableString* SQL = [[NSMutableString alloc] init];
        [SQL appendFormat:@"delete from %@",name];
        
        if ((where!=nil) && (where.count>0)){
            if((where!=nil) && (where.count>0)){
                NSArray* results = [BGTool where:where];
                [SQL appendString:results[0]];
                [arguments addObjectsFromArray:results[1]];
            }
        }
        debug(SQL);
        result = [db executeUpdate:SQL withArgumentsInArray:arguments];
    }];
    
    if (complete){
        complete(result);
    }
}
/**
 根据表名删除表格全部内容.
 */
-(void)clearTable:(NSString* _Nonnull)name complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* SQL = [NSString stringWithFormat:@"delete from %@",name];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    if (complete) {
        complete(result);
    }
}

/**
 删除表.
 */
-(void)dropTable:(NSString* _Nonnull)name complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString* SQL = [NSString stringWithFormat:@"drop table %@",name];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    if (complete) {
        complete(result);
    }
}
/**
 动态添加表字段.
 */
-(void)addTable:(NSString* _Nonnull)name key:(NSString* _Nonnull)key complete:(Complete_B)complete{
    NSAssert(name,@"表名不能为空!");
    __block BOOL result;
    [self.queue inDatabase:^(FMDatabase *db){
        NSString* SQL = [NSString stringWithFormat:@"alter table %@ add %@",name,[BGTool keyAndType:key]];
        debug(SQL);
        result = [db executeUpdate:SQL];
    }];
    if (complete) {
        complete(result);
    }

}
/**
 查询该表中有多少条数据
 */
-(NSInteger)countForTable:(NSString* _Nonnull)name where:(NSArray* _Nullable)where{
    NSAssert(name,@"表名不能为空!");
    NSAssert(!(where.count%3),@"条件数组错误!");
    NSMutableString* strM = [NSMutableString string];
    !where?:[strM appendString:@" where "];
    for(int i=0;i<where.count;i+=3){
        if ([where[i+2] isKindOfClass:[NSString class]]) {
            [strM appendFormat:@"%@%@%@'%@'",BG,where[i],where[i+1],where[i+2]];
        }else{
            [strM appendFormat:@"%@%@%@%@",BG,where[i],where[i+1],where[i+2]];
        }
        
        if (i != (where.count-3)) {
            [strM appendString:@" and "];
        }
    }
    __block NSUInteger count=0;
    [self.queue inDatabase:^(FMDatabase *db){
        NSString* SQL = [NSString stringWithFormat:@"select count (*) from %@%@",name,strM];
        debug(SQL);
        [db executeStatements:SQL withResultBlock:^int(NSDictionary *resultsDictionary) {
            count = [[resultsDictionary.allValues lastObject] integerValue];
            return 1;
        }];
    }];
    return count;
}
/**
 刷新数据库，即将旧数据库的数据复制到新建的数据库,这是为了去掉没用的字段.
 */
-(void)refreshTable:(NSString* _Nonnull)name keys:(NSArray<NSString*>* _Nonnull)keys complete:(Complete_I)complete{
    NSAssert(name,@"表名不能为空!");
    NSAssert(keys,@"字段数组不能为空!");
    __block dealState refreshstate = Error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    __weak typeof(self) BGSelf = self;
    //先查询出旧表数据
    [self queryWithTableName:name keys:nil where:nil complete:^(NSArray * _Nullable array){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        //接着删掉旧表
        [BGSelf dropTable:name complete:^(BOOL isSuccess){
            __strong typeof(BGSelf) secondSelf = strongSelf;
            if (isSuccess){
                //获取"唯一约束"字段名
                NSString* uniqueKey = [self getUnique:[NSClassFromString(name) new]];
                //创建新表
                [strongSelf createTableWithTableName:name keys:keys uniqueKey:uniqueKey complete:^(BOOL isSuccess){
                    if(isSuccess){
                        for(NSDictionary* oldDict in array){
                            NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
                            for(NSString* keyAndType in keys){
                                NSString* key = [keyAndType componentsSeparatedByString:@"*"][0];
                                //字段名前加上 @"BG_"
                                key = [NSString stringWithFormat:@"%@%@",BG,key];
                                if (oldDict[key]){
                                    newDict[key] = oldDict[key];
                                }
                            }
                            //将旧表的数据插入到新表
                            [secondSelf insertIntoTableName:name Dict:newDict complete:^(BOOL isSuccess){
                                if (isSuccess){
                                    if (!recordSuccess) {
                                        recordSuccess = YES;
                                    }
                                }else{
                                    if (!recordError) {
                                        recordError = YES;
                                    }
                                }
                            }];
                        }
                    }
                    
                }];
            }
        }];
    }];
    
    if (complete){
        if (recordError && recordSuccess) {
            refreshstate = Incomplete;
        }else if(recordError && !recordSuccess){
            refreshstate = Error;
        }else if (recordSuccess && !recordError){
            refreshstate = Complete;
        }else;
        complete(refreshstate);
    }
}

/**
 获取"唯一约束"
 */
-(NSString*)getUnique:(id)object{
    NSString* uniqueKey = nil;
    if([object respondsToSelector:NSSelectorFromString(@"uniqueKey")]){
        SEL uniqueKeySeltor = NSSelectorFromString(@"uniqueKey");
        uniqueKey = [object performSelector:uniqueKeySeltor];
    }
    return uniqueKey;
}
//判断类的变量名是否变更,然后改变表字段结构.
-(void)changeTableWhenClassIvarChange:(__unsafe_unretained Class)cla{
    NSString* tableName = NSStringFromClass(cla);
    NSMutableArray* newKeys = [NSMutableArray array];
    [self.queue inDatabase:^(FMDatabase *db){
        NSArray* keys = [BGTool getClassIvarList:cla onlyKey:NO];
        for (NSString* keyAndtype in keys){
            NSString* key = [[keyAndtype componentsSeparatedByString:@"*"] firstObject];
            key = [NSString stringWithFormat:@"%@%@",BG,key];
            if(![db columnExists:key inTableWithName:tableName]){
                [newKeys addObject:keyAndtype];
            }
        }
    }];
    
    //写在外面是为了防止数据库队列发生死锁.
    for(NSString* key in newKeys){
        //添加新字段
        [self addTable:tableName key:key complete:^(BOOL isSuccess){}];
    }
}

/**
 处理插入的字典数据并返回
 */
-(void)insertDictWithObject:(id)object complete:(Complete_B)complete{
    NSArray<BGModelInfo*>* infos = [BGModelInfo modelInfoWithObject:object];
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    for(BGModelInfo* info in infos){
        dict[info.sqlColumnName] = info.sqlColumnValue;
    }
    NSString* tableName = [NSString stringWithFormat:@"%@",[object class]];
    __weak typeof(self) BGSelf = self;
    [self insertIntoTableName:tableName Dict:dict complete:^(BOOL isSuccess){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (isSuccess) {
            if (complete) {
                complete(isSuccess);
            }
        }else{
            //检查表字段是否有改变
            [strongSelf changeTableWhenClassIvarChange:[object class]];
            [strongSelf insertIntoTableName:tableName Dict:dict complete:complete];
        }
    }];

}
/**
 存储一个对象.
 */
-(void)saveObject:(id _Nonnull)object complete:(Complete_B)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass([object class]);
    //获取"唯一约束"字段名
    NSString* uniqueKey = [self getUnique:object];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就新建
            [strongSelf createTableWithTableName:tableName keys:[BGTool getClassIvarList:[object class] onlyKey:NO] uniqueKey:uniqueKey complete:^(BOOL isSuccess) {
                if (isSuccess){
                    NSLog(@"建表成功 第一次建立 %@ 对应的表",tableName);
                }
            }];
        }
        
        //插入数据
        [strongSelf insertDictWithObject:object complete:complete];
    }];
}



/**
 查询对象.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nullable)where param:(NSString* _Nullable)param complete:(Complete_A)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            [strongSelf queryWithTableName:tableName param:param where:where complete:^(NSArray * _Nullable array) {
                NSArray* resultArray = [BGTool tansformDataFromSqlDataWithTableName:tableName array:array];
                if (complete) {
                    complete(resultArray);
                }
            }];
        }
    }];

}
/**
 根据条件查询对象.
 */
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla keys:(NSArray<NSString*>* _Nullable)keys where:(NSArray* _Nullable)where complete:(Complete_A)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            [strongSelf queryWithTableName:tableName keys:keys where:where complete:^(NSArray * _Nullable array) {
                NSArray* resultArray = [BGTool tansformDataFromSqlDataWithTableName:tableName array:array];
                if (complete) {
                    complete(resultArray);
                }
            }];
        }
    }];
}

//根据keyPath查询对象
-(void)queryObjectWithClass:(__unsafe_unretained _Nonnull Class)cla forKeyPath:(NSString* _Nonnull)keyPath value:(id _Nonnull)value complete:(Complete_A)complete{
    //检查是否建立了跟对象相对应的数据表
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回空
            if (complete) {
                complete(nil);
            }
        }else{
            [strongSelf queryWithTableName:NSStringFromClass([self class]) forKeyPath:keyPath value:value complete:^(NSArray * _Nullable array) {
                NSArray* resultArray = [BGTool tansformDataFromSqlDataWithTableName:tableName array:array];
                if (complete) {
                    complete(resultArray);
                }
            }];
        }
    }];

}
/**
 根据条件改变对象的所有变量值.
 */
-(void)updateWithObject:(id _Nonnull)object where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    NSArray<BGModelInfo*>* infos = [BGModelInfo modelInfoWithObject:object];
    NSMutableDictionary* valueDict = [NSMutableDictionary dictionary];
    for(BGModelInfo* info in infos){
        valueDict[info.sqlColumnName] = info.sqlColumnValue;
    }
    NSString* tableName = NSStringFromClass([object class]);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [strongSelf updateWithTableName:tableName valueDict:valueDict where:where complete:complete];
        }
    }];
}

/**
 根据条件改变对象的部分变量值.
 */
-(void)updateWithClass:(__unsafe_unretained _Nonnull Class)cla valueDict:(NSDictionary* _Nonnull)valueDict where:(NSArray* _Nullable)where complete:(Complete_B)complete{
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
          [strongSelf updateWithTableName:tableName valueDict:valueDict where:where complete:complete];
        }
    }];
}
/**
 根据条件删除对象表中的对象数据.
 */
-(void)deleteWithClass:(__unsafe_unretained _Nonnull Class)cla where:(NSArray* _Nonnull)where complete:(Complete_B)complete{
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [strongSelf deleteWithTableName:tableName where:where complete:complete];
        }
    }];
    
}
/**
 根据类删除此类所有表数据.
 */
-(void)clearWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(Complete_B)complete{
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist) {
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [strongSelf clearTable:tableName complete:complete];
        }
    }];
}
/**
 根据类,删除这个类的表.
 */
-(void)dropWithClass:(__unsafe_unretained _Nonnull Class)cla complete:(Complete_B)complete{
    NSString* tableName = NSStringFromClass(cla);
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:tableName complete:^(BOOL isExist){
        __strong typeof(BGSelf) strongSelf = BGSelf;
        if (!isExist){//如果不存在就返回NO
            if (complete) {
                complete(NO);
            }
        }else{
            [strongSelf dropTable:tableName complete:complete];
        }
    }];
}
/**
 将某类表的数据拷贝给另一个类表
 */
-(void)copyClass:(__unsafe_unretained _Nonnull Class)srcCla to:(__unsafe_unretained _Nonnull Class)destCla keyDict:(NSDictionary* const _Nonnull)keydict append:(BOOL)append complete:(Complete_I)complete{
    NSAssert(srcCla,@"源类不能为空!");
    NSAssert(destCla,@"目标类不能为空!");
    NSString* srcTable = NSStringFromClass(srcCla);
    NSString* destTable = NSStringFromClass(destCla);
    NSArray* destKeys = keydict.allValues;
    NSArray* srcKeys = keydict.allKeys;
    //检测用户的key是否写对了,否则抛出异常
    NSArray* srcOnlyKeys = [BGTool getClassIvarList:srcCla onlyKey:YES];
    NSArray* destOnlyKeys = [BGTool getClassIvarList:destCla onlyKey:YES];
    for(int i=0;i<srcKeys.count;i++){
        if (![srcOnlyKeys containsObject:srcKeys[i]]) {
            @throw [NSException exceptionWithName:@"源类变量名称写错" reason:@"请检查keydict中的srcKey是否书写正确!" userInfo:nil];
        }else if(![destOnlyKeys containsObject:destKeys[i]]){
            @throw [NSException exceptionWithName:@"目标类变量名称写错" reason:@"请检查keydict中的destKey字段是否书写正确!" userInfo:nil];
        }else;
    }
    [self isExistWithTableName:srcTable complete:^(BOOL isExist) {
        NSAssert(isExist,@"原类中还没有数据,不能复制");
    }];
    __weak typeof(self) BGSelf = self;
    [self isExistWithTableName:destTable complete:^(BOOL isExist) {
        if (!isExist){
            NSMutableArray* destKeyAndTypes = [NSMutableArray array];
            NSArray* destClassKeys = [BGTool getClassIvarList:destCla onlyKey:NO];
            for(NSString* destKey in destKeys){
                for(NSString* destClassKey in destClassKeys){
                    if ([destClassKey containsString:destKey]) {
                        [destKeyAndTypes addObject:destClassKey];
                    }
                }
            }
            //获取"唯一约束"字段名
            NSString* uniqueKey = [self getUnique:[destCla new]];
            [BGSelf createTableWithTableName:destTable keys:destKeyAndTypes uniqueKey:uniqueKey complete:^(BOOL isSuccess) {
                NSAssert(isSuccess,@"目标表创建失败,复制失败!");
            }];
        }else{
            if (!append){//覆盖模式,即将原数据删掉,拷贝新的数据过来
                [BGSelf clearTable:destTable complete:nil];
            }
        }
    }];
    __block dealState copystate = Error;
    __block BOOL recordError = NO;
    __block BOOL recordSuccess = NO;
    [self queryWithTableName:srcTable keys:srcKeys where:nil complete:^(NSArray * _Nullable array) {
        for(NSDictionary* srcDict in array){
            NSMutableDictionary* destDict = [NSMutableDictionary dictionary];
            for(int i=0;i<srcKeys.count;i++){
                //字段名前加上 @"BG_"
                NSString* destSqlKey = [NSString stringWithFormat:@"%@%@",BG,destKeys[i]];
                NSString* srcSqlKey = [NSString stringWithFormat:@"%@%@",BG,srcKeys[i]];
                destDict[destSqlKey] = srcDict[srcSqlKey];
            }
            [BGSelf insertIntoTableName:destTable Dict:destDict complete:^(BOOL isSuccess) {
                if (isSuccess){
                    if (!recordSuccess) {
                        recordSuccess = YES;
                    }
                }else{
                    if (!recordError) {
                        recordError = YES;
                    }
                }
            }];
        }
    }];
    
    if (complete){
        if (recordError && recordSuccess) {
            copystate = Incomplete;
        }else if(recordError && !recordSuccess){
            copystate = Error;
        }else if (recordSuccess && !recordError){
            copystate = Complete;
        }else;
        complete(copystate);
    }
}

@end
