//
//  LYSQLTool.m
//  SQL
//
//  Created by CloudL on 2018/9/25.
//  Copyright © 2018 KOOCAN. All rights reserved.
//

#define kOCTypeDBNameInteger @"INTEGER"
#define kOCTypeDBNameReal @"REAL"
#define kOCTypeDBNameArr @"ARR"
#define kOCTypeDBNameDict @"DICT"
#define kOCTypeDBNameText @"TEXT"

#define kLYName @"name"
#define kLYType @"type"

#import "LYSQLTool.h"
#import <sqlite3.h>
#import <objc/runtime.h>

typedef void(^LYSQLThreadBlock)(void);

@interface LYSQLThread : NSObject
@property (strong, nonatomic) NSThread *innerThread;
@end
@implementation LYSQLThread

- (instancetype)init
{
    if (self = [super init]) {
        self.innerThread = [[NSThread alloc] initWithBlock:^{
            
            // 创建上下文（要初始化一下结构体）
            CFRunLoopSourceContext context = {0};
            
            // 创建source
            CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
            
            // 往Runloop中添加source
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
            
            // 销毁source
            CFRelease(source);
            
            // 启动
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0e10, false);
            
        }];
        
        [self.innerThread start];
    }
    return self;
}

- (void)executeTask:(LYSQLThreadBlock)task
{
    if (!self.innerThread || !task) return;
    
    [self performSelector:@selector(__executeTask:) onThread:self.innerThread withObject:task waitUntilDone:NO];
}

- (void)stop
{
    if (!self.innerThread) return;
    
    [self performSelector:@selector(__stop) onThread:self.innerThread withObject:nil waitUntilDone:YES];
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    [self stop];
}

#pragma mark - private methods
- (void)__stop
{
    CFRunLoopStop(CFRunLoopGetCurrent());
    self.innerThread = nil;
}

- (void)__executeTask:(LYSQLThreadBlock)task
{
    task();
}



@end




NSString * const kLYDBVersion = @"kLYDBVersion";


@interface LYSQLTool ()

/** 数据库文件路径  */
@property (nonatomic , strong) NSString *path;

@property (nonatomic , assign) sqlite3 *sql3;

@property (nonatomic , strong) LYSQLThread *thread;
@end

@implementation LYSQLTool

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        self.path = path;
        self.thread = [[LYSQLThread alloc]init];
    }
    return self;
}


- (void)createTabel:(NSString *)tableName objectClass:(Class)objectClass results:(void(^)(BOOL results))results
{
    [self.thread executeTask:^{
        NSMutableString *sqlStr = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' ('id' INTEGER PRIMARY KEY AUTOINCREMENT,",tableName];
        NSArray *names =[NSArray arrayWithArray:[self propertyNameListWithClass:objectClass]];
        for (NSDictionary *dic in names) {
            NSString *name = dic[kLYName];
            NSString *type = dic[kLYType];
            [sqlStr appendString:[NSString stringWithFormat:@"'%@' %@ ,",name,type]];
        }
        NSString *str = [sqlStr substringToIndex:sqlStr.length-1];
        str = [str stringByAppendingString:@");"];
        
        [self execute:str results:results];
    }];
}

- (void)insertModel:(id)model fromTable:(NSString *)tableName results:(void(^)(BOOL results))results
{
    if (model == nil || tableName == nil) {
        if (results) {
            results(NO);
        }
        return;
    }
    
    [self.thread executeTask:^{
        NSDictionary *dict = [self dictionaryFromModel:model];
        
        if (dict.count < 1) {
            if (results) {
                results(NO);
            }
            return;
        }
        
        
        NSMutableString *keys = [NSMutableString string];
        NSMutableString *values = [NSMutableString string];
        
        
        for (int i = 0; i < dict.count; i++) {
            NSString *key = dict.allKeys[i];
            id value = dict[key];
            if ([value isKindOfClass:[NSString class]]) {
                value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"*^*"];
            }
            
            [keys appendFormat:@"%@,",key];
            [values appendFormat:@"'%@',",value];
        }
        
        //防止没有取到值
        if (keys.length < 1 || values.length < 1) {
            if (results) {
                results(NO);
            }
            return;
        }
        
        NSString *keyStr = [keys substringToIndex:keys.length -1];
        NSString *valuesStr = [values substringToIndex:values.length - 1];
        NSString *sql = [NSString stringWithFormat:@"insert into %@(%@) values(%@)",tableName,keyStr,valuesStr];
        
        [self execute:sql results:results];
    }];
}

#pragma mark - 根据条件语句查询表格里的数据,返回对象模型数组
- (void)queryWithConditionsStr:(NSString *)conditionsStr fromTable:(NSString *)table  backObject:(Class)object results:(void(^)(NSMutableArray *objectArr))results
{
    if (table == nil) {
        return;
    }

    [self.thread executeTask:^{
        NSMutableArray *objectArr = [NSMutableArray array];
        
        NSString *sqlStr = conditionsStr == nil ? [NSString stringWithFormat:@"SELECT *FROM %@",table] : [NSString stringWithFormat:@"SELECT * FROM %@ where %@",table,conditionsStr];
        
        [self open];
        sqlite3_stmt *stmt = nil;
        int res = sqlite3_prepare(self.sql3, sqlStr.UTF8String, -1, &stmt, NULL);
        if (res == SQLITE_OK) {
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                
                id objc = [[[object class] alloc]init];
                NSArray *array = [self propertyNameListWithClass:object];
                
                int count = sqlite3_column_count(stmt);
                for (int i = 0; i < count; i++) {
                    const char *columName = sqlite3_column_name(stmt, i);
                    const char *value = (const char*)sqlite3_column_text(stmt, i);
                    if (value!=NULL) {
                        NSString *ocStr = [NSString stringWithUTF8String:value];
                        ocStr = [ocStr stringByReplacingOccurrencesOfString:@"*^*" withString:@"'"];
                        for (NSDictionary *dict in array) {
                            NSString *name = dict[kLYName];
                            if ([name isEqualToString:[NSString stringWithUTF8String:columName]]) {
                                NSString *type = dict[kLYType];
                                if ([type isEqualToString:kOCTypeDBNameArr] || [type isEqualToString:kOCTypeDBNameDict]) {
                                    NSData * data = [ocStr dataUsingEncoding:NSUTF8StringEncoding];
                                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                    [objc setValue:result forKey:name];
                                }else{
                                    [objc setValue:ocStr forKey:name];
                                }
                            }
                        }
                    }
                }
                [objectArr addObject:objc];
            }
            sqlite3_finalize(stmt);
        }
        [self close];
        
        if (results) {
            results(objectArr);
        }
    }];
}

#pragma mark - 数据库升级
- (void)updateTableWithTableName:(NSString *)tableName class:(Class)objectClass
{
    [self.thread executeTask:^{
        //获取表的所有字段
        NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info(%@)",tableName];
        NSMutableArray *columnNameArr = [NSMutableArray array];
        [self open];
        sqlite3_stmt *statement = NULL;
        sqlite3_prepare_v2(self.sql3, sql.UTF8String, -1, &statement, NULL);
        while (sqlite3_step(statement) == SQLITE_ROW) {
            const unsigned char * name = sqlite3_column_text(statement, 1);
            NSString *columnName = [[NSString alloc] initWithUTF8String:(char*)name];
            if (![columnName isEqualToString:@"id"]) {
                [columnNameArr addObject:columnName];
            }
        }
        
        //删除已经存在的字段
        NSArray *dictArr = [self propertyNameListWithClass:objectClass];
        NSMutableArray *mutableDictArr = [NSMutableArray arrayWithArray:dictArr];
        for (NSString *columnName in columnNameArr) {
            for (NSDictionary *dict in dictArr) {
                NSString *name = dict[kLYName];
                if ([columnName isEqualToString:name]) {
                    [mutableDictArr removeObject:dict];
                }
            }
        }
        
        if (mutableDictArr.count) {
            for (NSDictionary *dict in mutableDictArr) {
                NSString *columnName = dict[kLYName];
                NSString *type = dict[kLYType];
                if (columnName && type) {
                    NSString *updateStr = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@",tableName,columnName,type];
                    [self execute:updateStr results:^(BOOL results) {
                        NSLog(@"数据操作升级:%d",results);
                    }];
                }
            }
        }
        
        [self close];
    }];
}




#pragma mark - 方法抽取
- (BOOL)open
{
    if (_path == nil) {
        return NO;
    }
    
    return !sqlite3_open(_path.UTF8String, &_sql3);
}

- (BOOL)close
{
    return !sqlite3_close(_sql3);
}

- (void)execute:(NSString *)sql results:(void(^)(BOOL results))results
{
    int res = -100;
    [self open];
    res = sqlite3_exec(self.sql3, sql.UTF8String, NULL, NULL, NULL);
    NSLog(@"LYDBManager>>>>>数据库执行线程-%d-%@",res,[NSThread currentThread]);
    [self close];
    
    BOOL temp = res == 0;
    if (temp) {
        NSLog(@"LYDBManager>>>>>执行结果成功-%d-%@",res,[NSThread currentThread]);
    }else{
        NSLog(@"LYDBManager>>>>>执行结果失败-%d-%@",res,[NSThread currentThread]);
    }
    if (results) {
        results(temp);
    }
}


//获取类的所有属性名称与类型
- (NSArray *)propertyNameListWithClass:(Class)cls
{
    NSMutableArray *arr = [NSMutableArray array];
    
    Class superClass = class_getSuperclass(cls);
    while (![NSStringFromClass(superClass) isEqualToString:@"NSObject"]) {
        unsigned int superClassCount = 0;
        objc_property_t *superClassPros = class_copyPropertyList(superClass, &superClassCount);
        for (int i = 0; i < superClassCount; i++) {
            NSString *name =[NSString stringWithFormat:@"%s",property_getName(superClassPros[i])];
            NSString *type = [self attrValueWithProperty:superClassPros[i]];
            //类型转换
            NSString *OCType = [self OCTypeWithTypeEncoding:type];
            if (OCType) {
                NSDictionary *dic = @{kLYName:name,kLYType:OCType};
                [arr addObject:dic];
            }
        }
        free(superClassPros);
        superClass = class_getSuperclass(superClass);
    }
    unsigned int count;
    objc_property_t *pros = class_copyPropertyList(cls, &count);
    for (int i = 0; i < count; i++) {
        NSString *name =[NSString stringWithFormat:@"%s",property_getName(pros[i])];
        NSString *type = [self attrValueWithProperty:pros[i]];
        //类型转换
        NSString *OCType = [self OCTypeWithTypeEncoding:type];
        if (OCType) {
            NSDictionary *dic = @{kLYName:name,kLYType:OCType};
            [arr addObject:dic];
        }
    }
    free(pros);
    
    return arr;
}

//获取属性的特征值
- (NSString *)attrValueWithProperty:(objc_property_t)pro
{
    unsigned int count = 0;
    objc_property_attribute_t *attrs = property_copyAttributeList(pro, &count);
    for (int i = 0; i < count; i++) {
        objc_property_attribute_t attr = attrs[i];
        if (strcmp(attr.name, @"T".UTF8String) == 0) {
            NSString *value = [NSString stringWithUTF8String:attr.value];
            free(attrs);
            return value;
        }
    }
    free(attrs);
    return nil;
}

//根据类型编码设置类型
- (NSString *)OCTypeWithTypeEncoding:(NSString *)typeEncoding
{
    //类型转换
    if ([typeEncoding isEqualToString:@"q"] || [typeEncoding isEqualToString:@"Q"] || [typeEncoding isEqualToString:@"i"] || [typeEncoding isEqualToString:@"I"] || [typeEncoding isEqualToString:@"l"] || [typeEncoding isEqualToString:@"L"] ) {
        return kOCTypeDBNameInteger;
    }else if([typeEncoding isEqualToString:@"f"] || [typeEncoding isEqualToString:@"d"]){
        return kOCTypeDBNameReal;
    }else if([typeEncoding containsString:@"Dictionary"]){
        return kOCTypeDBNameDict;
    }else if ([typeEncoding containsString:@"Array"]){
        return kOCTypeDBNameArr;
    }else if([typeEncoding containsString:@"String"] ||
             [typeEncoding isEqualToString:@"B"] ||
             [typeEncoding containsString:@"NSNumber"]){
        return kOCTypeDBNameText;
    }else{
        NSLog(@"LYDBManager>>>>>未识别的typeEncoding>>>>>%@",typeEncoding);
        return nil;
    }
}

//对象转换为字典
- (NSDictionary *)dictionaryFromModel:(id)model
{
    if (model == nil) {
        return nil;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    Class superClass = class_getSuperclass([model class]);
    while (![NSStringFromClass(superClass) isEqualToString:@"NSObject"]){
        NSMutableDictionary *dict = [self modelDictWithClass:superClass model:model];
        if (dict.allKeys.count > 0) {
            [dictionary addEntriesFromDictionary:dict];
        }
        superClass = class_getSuperclass(superClass);
    }
    
    Class modelClass = object_getClass(model);
    NSMutableDictionary *dict = [self modelDictWithClass:modelClass model:model];
    if (dict.allKeys.count > 0) {
        [dictionary addEntriesFromDictionary:dict];
    }
    
    return dictionary;
}

//根据类 和 实体对象获取 对象的属性名和对应值的字典
- (NSMutableDictionary *)modelDictWithClass:(Class)class model:(id)model
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    unsigned int count = 0;
    objc_property_t *pros = class_copyPropertyList(class, &count);
    
    for (int i = 0; i < count; i++) {
        objc_property_t pro = pros[i];
        //获取属性名称
        NSString *name = [NSString stringWithFormat:@"%s", property_getName(pro)];
        //获取属性对应的值
        id value = [model valueForKey:name];
        //判断值是否为空
        if (value != nil) {
            //判断是否为数组
            if ([value isKindOfClass:[NSArray class]]) {
                NSArray *valueArr = value;
                //判断数组内的对象是否还是数组
                id firstObject = valueArr.firstObject;
                while ([firstObject isKindOfClass:[NSArray class]]) {
                    NSArray *arr = firstObject;
                    firstObject = arr.firstObject;
                }
                
                if (firstObject == nil) {
                    continue;
                }
                
                //直到取出最后一层的对象
                NSString *className = NSStringFromClass([firstObject class]);
                //判断是否是支持的数据类型
                if ([className isEqualToString:@"__NSCFNumber"] ||
                    [className isEqualToString:@"__NSCFConstantString"] ||
                    [className isEqualToString:@"__NSCFString"]) {
                    NSData * data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
                    value = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                }else{
                    value = nil;
                }
            
            }else if ([value isKindOfClass:[NSDictionary class]]){
                NSDictionary *valueDict = value;
                for (NSString *key in valueDict) {
                    id object = valueDict[key];
                    NSString *className = NSStringFromClass([object class]);
                    if ([className isEqualToString:@"__NSCFNumber"] ||
                        [className isEqualToString:@"__NSCFConstantString"] ||
                        [className isEqualToString:@"__NSCFString"]) {
                        continue;
                    }else{
                        value = nil;
                    }
                }
                
                if (value != nil) {
                    NSData * data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
                    value = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                }
            }
            
            if (value != nil) {
                [dict setObject:value forKey:name];
            }
        }
    }
    free(pros);
    return dict;
}

- (BOOL)isFoundationType:(NSString *)className
{
    if ([className isEqualToString:@"__NSCFNumber"] ||
        [className isEqualToString:@"__NSCFConstantString"] ||
        [className isEqualToString:@"__NSCFString"] ||
        [className isEqualToString:@"__NSArrayI"] ||
        [className isEqualToString:@"__NSArrayM"] ||
        [className isEqualToString:@"__NSSingleEntryDictionaryI"] ||
        [className isEqualToString:@"__NSDictionaryM"]) {
        return YES;
    }
    
    return NO;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}




#pragma mark - Get

@end


@implementation NSString (LYExtension)

//防止字符串转integer崩溃
- (NSInteger)unsignedLongLongValue
{
    return [self integerValue];
}
@end

