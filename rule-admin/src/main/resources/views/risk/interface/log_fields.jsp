<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>规则接口日志字段维护</title>
<link rel="stylesheet" href="/style/themes/default/easyui.css">
<link rel="stylesheet" href="/style/themes/icon.css">
<script type="text/javascript" src="/style/jquery-1.8.0.min.js"></script>
<script type="text/javascript" src="/style/jquery.easyui.min.js"></script>
<script type="text/javascript" src="/style/locale/easyui-lang-zh_CN.js"></script>
<script type="text/javascript">
$(function(){
	getInterfaces();
	
	$("#search").click(search);
	$("#addButton").click(function() {
		showEditor();
	});
	$("#saveButton").click(save);
});

function getInterfaces() {
	$.getJSON('/ccmis/risk/interface/InterfaceEnum', {}, function(json) {
		if (json.totalSize != null && json.totalSize > 0) {
			var str = '';
			for (var i=0; i<json.list.length; i++) {
				str += '<option value="'+json.list[i].code+'">'+json.list[i].name+'</option>';
			}
			
			$("#interfaceList").html('<option value="" selected="selected">全部</option>' + str);
			$("#selectedInterface").html(str);
		}
		
		$.getJSON('/ccmis/risk/ruleFied/listOrderByCategory.json', {}, function(json) {  
		    if (json != null) {
			    var str = "[";
			    var category = null;
			    var id = 1;
			    for (var i=0; i<json.length; i++) {
			    	if (category == null) {
				    	category = json[i].category;
			    		str += "{";
			    		str += '"id":"p' + id + '",';
			    		str += '"text":' + '"'+ category +'",'
			    		str += '"children":[';
			    	}
			    	else if (category != json[i].category) {
			    		category = json[i].category;
			    		id += 1;
			    		str = str.substring(0, str.length - 1);
			    		str += "]},";
			    		str += "{";
			    		str += '"id":"p' + id + '",';
			    		str += '"text":' + '"'+ category +'",'
			    		str += '"children":[';
			    	}
			    		
			    	str += "{"
			    	str += '"id":' + json[i].id + ',';
			    	str += '"text":' + '"'+ json[i].description +'"},'
			    }
			    
			    str = str.substring(0, str.length - 1) + "]}]";
		
			    $('#fields').combotree('loadData', eval("(" + str + ")"));
		    }
		});
	});
	
	
}

function search() {
	$('#grid').datagrid({
		queryParams:{ 
			interfaceName:$("#interfaceList").val()
		}
	});
}

function showEditor(interfaceName) {
	if (interfaceName == null || interfaceName == 0) {
		//reset form
		$("#selectedInterface option").first().attr("selected", "selected");
		$('#fields').combotree('setValues', []);
		
		$('#showDetail').window('open');
	}
	else {
		//edit
		$.getJSON('/ccmis/risk/interface/detailFields.json', {interfaceName:interfaceName}, function(json) {
			if (json.key == undefined) {
				alert("查询数据错误");
				return;
			}
			
			$("#selectedInterface option").each(function(i) {
				if ($(this).val() == json.key) {
					$(this).attr("selected", "selected");
				}
			});
			var values = json.value.split(',');
			$('#fields').combotree('setValues', values);
			$('#showDetail').window('open');
		});
	}
}

function save() {
	var values = $("#fields").combotree("getValues");
	if (values == null || values.length < 1) {
		$.messager.show({title : '操作失败',msg : "字段必须输入。"});
		return;
	}
	var str = "";
	for (var i=0; i<values.length; i++) {
		str += values[i];
		if (i != (values.length -1)) {
			str += ",";
		}
	}
	$.post('/ccmis/risk/interface/saveFields', {interfaceName:$("#selectedInterface").val(), fields:str}, function(data) {
		if (data != "0") {
			$.messager.show({title : '操作失败',msg : "操作失败.code=" + data});
		}
		else {
			$.messager.show({title : '操作成功',msg : "操作成功。"});
			$('#showDetail').window('close');
			search();
		}
	});
}

function gridformatter(value,rec,index){
	return '<a href="javascript:void(0)" onclick="showEditor(\''+rec.key+'\')">修改</a>&nbsp;<a href="javascript:void(0)" onclick="delete('+rec.key+')">删除</a>';
}
</script>
</head>
<body>
	<table id="grid" class="easyui-datagrid" style="height: 500px"
		data-options="title:'规则接口日志字段维护',rownumbers:true,singleSelect:true,pagination:true,url:'/ccmis/risk/interface/logFieldList.json',toolbar:'#tb'">
		<thead>
			<tr>
				<th data-options="field:'key',width:160,align:'center'">接口名</th>
				<th	data-options="field:'value',width:400,align:'center'">字段</th>
				<th	data-options="field:'op',width:80,align:'center',formatter:function(value,rec,index){return gridformatter(value,rec,index);}">操作</th>
			</tr>
		</thead>
	</table>
	<div id="tb" style="padding: 5px; height: auto">
		<div style="margin-bottom: 15px">
			接口:<select id="interfaceList" name="interfaceList" style="width: 200px;"></select> 
			<a href="javascript:void(0)" id="search" class="easyui-linkbutton" iconCls="icon-search">搜索</a>
		</div>
		<div style="margin-bottom: 15px">
			<a href="javascript:void(0)" id="addButton" class="easyui-linkbutton" iconCls="icon-add">添加</a>
		</div>
	</div>

	<div id="showDetail" class="easyui-window" title="编辑规则日志字段" data-options="modal:true,closed:true,collapsible:false,minimizable:false,maximizable:false,iconCls:'icon-save'" style="width:300px;height:200px;padding:10px;">
   		<form id="ff" method="post">
            <table>  
                <tr>
                    <td>接口名:</td>  
                    <td>
                    	<select id="selectedInterface" name="selectedInterface" style="width: 200px;"></select>
                    </td>  
                </tr>
                <tr>  
                    <td>字段:</td>  
                    <td>
                    	<select id="fields" class="easyui-combotree" multiple cascadeCheck="false" style="width:200px;"></select>
                    </td>  
                </tr>
                <tr>    
                    <td colspan="2" align="center"><a href="javascript:void(0)" id="saveButton" class="easyui-linkbutton" iconCls="icon-save">保存</a></td>  
                </tr>
            </table>
        </form>
	</div>
</body>
</html>