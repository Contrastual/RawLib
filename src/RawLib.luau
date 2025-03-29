--[[
   Copyright 2025 Ivashenko Arsenij

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
]]

--!optimize 2
--!strict 

--this function returns the metamethod and also tries to predict if it was patched
local function returnFunc()
	local line, func = debug.info(2, "f")
	
	if line ~= -1 or func == error then
		return nil
	end
	
	return func
end

--test functions
local function index(table:any,index:string) : any return table[index] end
local function newIndex(table:any,index:string,value:any) : () table[index] = value end

local function mul(table:any,value:number) : any return table*value end
local function add(table:any,value:number) : any return table+value end
local function sub(table:any,value:number) : any return table-value end
local function div(table:any,value:number) : any return table/value end

type OperatorFunction = (first: any, second: any) -> any
type RawLib = {
	index: (table: any) -> ((table: any, index: string) -> any),
	newIndex: (table: any) -> ((table: any, index: string, value: any) -> ()),
	add: (table: any) -> OperatorFunction,
	sub: (table: any) -> OperatorFunction,
	div: (table: any) -> OperatorFunction,
	mul: (table: any) -> OperatorFunction,
}

local cachedClosures = {}

local function fetch(table: any, name: string, testValue: any, testFunc: (...any) -> ...any)
	local type = typeof(table)

	local cache = cachedClosures[type]
	if not cache then
		cache = {}
		cachedClosures[type] = cache
	end

	local closure = cache[name]
	if closure then
		return closure
	end

	local _, closure = xpcall(testFunc, returnFunc, table, testValue, nil)
	if closure then
		return closure
	end

	warn(type, name, "raw call is not available")
	return testFunc
end

return {
	index = function(table) return fetch(table, "index", "", index) end,
	newIndex = function(table) return fetch(table, "newIndex", "", newIndex) end,
	mul = function(table) return fetch(table, "mul", "", mul) end,
	add = function(table) return fetch(table, "add", "", add) end,
	sub = function(table) return fetch(table, "sub", "", sub) end,
	div = function(table) return fetch(table, "div", "", div) end,
} :: RawLib
