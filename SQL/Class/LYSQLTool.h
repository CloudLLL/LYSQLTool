//
//  LYSQLTool.h
//  SQL
//
//  Created by CloudL on 2018/9/25.
//  Copyright © 2018 KOOCAN. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LYSQLTool : NSObject

/**
 初始化方法
 
 @param path 数据库文件路径
 @return 实例对象
 */
- (instancetype)initWithPath:(NSString *)path;

/**
 根据一个数据模型创建一个表格
 
 @param tableName 表名
 @param objectClass 数据模型类
 @param results 结果
 */
- (void)createTabel:(NSString *)tableName objectClass:(Class)objectClass results:(void(^)(BOOL results))results;



/**
 插入数据模型到表格
 
 @param model 数据模型对象
 @param tableName 表名
 @param results 结果
 */
- (void)insertModel:(id)model fromTable:(NSString *)tableName results:(void(^)(BOOL results))results;

/**
 根据条件语句查询
 
 @param conditionsStr 条件语句
 @param table 表名
 @param object 需要转换的模型对象类
 @param results 结果
 */
- (void)queryWithConditionsStr:(NSString *)conditionsStr fromTable:(NSString *)table  backObject:(Class)object results:(void(^)(NSMutableArray *objectArr))results;

/**
 数据库升级操作
 
 @param tableName 表名
 @param objectClass 数据模型类
 */
- (void)updateTableWithTableName:(NSString *)tableName class:(Class)objectClass;
@end

NS_ASSUME_NONNULL_END
