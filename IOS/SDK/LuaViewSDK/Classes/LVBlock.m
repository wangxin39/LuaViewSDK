//
//  LVLuaFunction.m
//  LVSDK
//
//  Created by dongxicheng on 4/27/15.
//  Copyright (c) 2015 dongxicheng. All rights reserved.
//

#import "LVBlock.h"
#import "LView.h"
#import "LVHeads.h"

@interface LVBlock ()
@property (nonatomic,weak) LView* lview;
@property (nonatomic,strong) id retainKey;
@property (nonatomic,strong) NSArray* returnValues;
@end

@implementation LVBlock

- (id) initWith:(lua_State*)L statckID:(int) idx{
    self = [super init];
    if( self ){
        self.retainKey = [[NSMutableString alloc] init];
        self.lview = LV_LUASTATE_VIEW(L);
        if( lua_type(L, idx)==LUA_TFUNCTION ) {
            [LVUtil registryValue:L key:self.retainKey stack:idx];
        }
    }
    return self;
}

- (id) initWith:(lua_State*)L globalName:(NSString*) globalName{
    self = [super init];
    if( self ){
        self.retainKey = [[NSMutableString alloc] init];
        self.lview = LV_LUASTATE_VIEW(L);
        
        if ( [globalName rangeOfString:@"."].length>0 ){
            [self resetFunctionByNames:globalName];
        } else {
            lua_getglobal(L, globalName.UTF8String);
            if( lua_type(L, -1)==LUA_TFUNCTION ) {
                [LVUtil registryValue:L key:self.retainKey stack:-1];
            }
        }
    }
    return self;
}

-(void) resetFunctionByNames:(NSString*) globalName{
    NSArray * names = [globalName componentsSeparatedByString:@"."];
    lua_State* L = self.lview.l;
    if( names.count>0 ){
        NSString* name0 = names.firstObject;
        lua_getglobal(L, name0.UTF8String);
        for( int i=1; i<names.count; i++ ){
            NSString* key = names[i];
            if( lua_type(L, -1) == LUA_TTABLE ){
                lua_getfield(L, -1, key.UTF8String);
            } else {
                break;
            }
        }
        if( lua_type(L, -1)==LUA_TFUNCTION ) {
            [LVUtil registryValue:L key:self.retainKey stack:-1];
        }
    }
}

- (void) dealloc{
    lua_State* L = self.lview.l;
    if( L ) {
        [LVUtil unregistry:L key:self.retainKey];
    }
}

- (NSString*) callWithArgs:(NSArray*) args{
    lua_State* L = self.lview.l;
    if( L ) {
        lua_checkstack(L, (int)args.count*2+2 );
        
        int oldStackNum = lua_gettop(L);
        
        for( int i=0; i<args.count; i++ ){
            id obj = args[i];
            lv_pushNativeObject(L,obj);
        }
        
        [LVUtil pushRegistryValue:L key:self.retainKey];
        
        NSString* ret = lv_runFunctionWithArgs(L, (int)args.count, self.returnValueNum);
        
        NSMutableArray* values = [[NSMutableArray alloc] init];
        int newStackNum = lua_gettop(L);
        for( int i=oldStackNum+1; i<=newStackNum; i++ ){
            id value = lv_luaValueToNativeObject(L, i);
            value = ( (value==nil) ? [NSNull null] : value );
            [values addObject:value];
        }
        if ( values.count>0 ) {
            self.returnValues = values;
        } else {
            self.returnValues = nil;
        }
        //lua_settop(L, oldStackNum);
        return ret;
    }
    return nil;
}

-(void) pushFunctionToStack{
    lua_State* L = self.lview.l;
    if( L ){
        [LVUtil pushRegistryValue:L key:self.retainKey];
    }
}

-(id) returnValue:(int)index{
    if( index>=0 && index<self.returnValues.count ){
        id value = self.returnValues[index];
        if (value != [NSNull null] ) {
            return value;
        }
    }
    return nil;
}

@end
