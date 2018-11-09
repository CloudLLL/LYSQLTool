//
//  TestModel.h
//  SQL
//
//  Created by CloudL on 2018/9/25.
//  Copyright © 2018 KOOCAN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestModel2.h"



NS_ASSUME_NONNULL_BEGIN

@interface TestModel : NSObject

/** <#注释#>  */
@property (nonatomic , assign) NSInteger age;
/** <#注释#>  */
@property (nonatomic , assign) int intage;

/**   */
@property (nonatomic , assign) NSUInteger uint;

/** <#注释#>  */
@property (nonatomic , assign) float height;
/** <#注释#>  */
@property (nonatomic , assign) double dheight;
/** <#注释#>  */
@property (nonatomic , strong) NSString *name;
/** <#注释#>  */
@property (nonatomic , strong) NSMutableString *Mname;
/** <#注释#>  */
@property (nonatomic , strong) NSArray *arr;
/** <#注释#>  */
@property (nonatomic , strong) NSMutableArray *marr;
/** <#注释#>  */
@property (nonatomic , strong) NSDictionary *dict;
/** <#注释#>  */
@property (nonatomic , strong) NSMutableDictionary *mdict;
/** <#注释#>  */
@property (nonatomic , strong) NSNumber *num;
/** <#注释#>  */
//@property (nonatomic , strong) TestModel2 *model;

/** <#注释#>  */
@property (nonatomic , strong) NSString *updateStr;

/** <#注释#>  */
@property (nonatomic , strong) NSDictionary *updateDict;

/** <#注释#>  */
@property (nonatomic , strong) NSDictionary *updateArr;

/** <#注释#>  */
@property (nonatomic , strong) NSNumber *updatenum;


/** <#注释#>  */
@property (nonatomic , assign) float updatef;
/** <#注释#>  */
@property (nonatomic , assign) NSInteger updateint;


/** <#注释#>  */
@property (nonatomic , strong) NSArray *updateArrrrrrrrr;

@end

NS_ASSUME_NONNULL_END
