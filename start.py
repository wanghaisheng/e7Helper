"""
 File       : start.py
 Time       ：2023/6/25 18:19
 Author     ：🍍
 Description：
"""
import hashlib
import os
import re
import shutil
from datetime import datetime

# 懒人精灵项目路径
projectPath = r'D:\program\懒人精灵3.8.6.2\script\e8'
# 懒人精灵项目打包路径
packagePath = r'D:\program\懒人精灵3.8.6.2\script\e8\out\script.lr'

# https://gitcode.net/otato001/e7hepler.git
# https://gitea.com/boluoii/e7Helper.git
# git remote set-url --add --push origin https://gitcode.net/otato001/e7hepler.git

# 文件映射
fileMapping = {
	'': {'mapper': '.lcproj'},  # 添加根目录
	'脚本': {'mapper': '.lua'},
	'资源': {'mapper': '.rc'},
	'界面': {'mapper': '.ui'},
	'插件': {'mapper': '.luae', 'child': {'x86': {}, 'armeabi-v7a': {}}}
}
md5 = hashlib.md5()


# 会自动将文件复制到你的懒人精灵下(自动创建项目)
def copy():
	if input("确定复制吗 y/N\n") != 'y':
		return
	mkDir(fileMapping, projectPath)
	print('复制成功!')
	print('即将打开项目文件夹..')
	os.startfile(projectPath)


# 创建目录
def mkDir(fm, path):
	for v in fm:
		curPath = os.path.join(path, v)
		if not os.path.exists(curPath):
			os.mkdir(curPath)
		mapper = fm[v].get('mapper')
		if mapper:
			copyFile(mapper, curPath)
		if fm[v].get('child'):
			mkDir(fm[v].get('child'), curPath)


# 复制文件
def copyFile(mapperStr, dest):
	files = []
	for v in os.listdir():
		if v.rfind(mapperStr) != -1:
			files.append(v)
	for v in files:
		print(v)
		content = ''
		if v.rfind('.rc') != -1:
			with open(os.path.join(os.getcwd(), v), mode='rb') as f:
				content = f.read()
			with open(os.path.join(dest, re.search(r"([^\\]+)\.[^.]+$", v).group()), mode='wb') as f:
				f.write(content)
		else:
			# 一般文本文件都是UTF-8, 但是懒人IDE比较特殊只能GB18030
			with open(os.path.join(os.getcwd(), v), mode="r", encoding="UTF-8") as f:
				content = f.read()
			with open(os.path.join(dest, v), mode="w", encoding="GB18030") as f:
				f.write(content)


# 保存文件
def saveAndPush():
	# 对main.lua部分属性进行修改(已经修改过的)
	mainLuaPath = os.path.join(projectPath, '脚本', 'main.lua')
	with open(mainLuaPath, "r", encoding='GB18030') as f:
		lines = f.readlines()
		ss = ""
		for line in lines:
			if re.match('-- hotupdate_disabled = true', line):
				line = 'hotupdate_disabled = true\n'
			if re.match('release_date = .*', line):
				line = 'release_date = "' + \
					   str(datetime.now().strftime("%m.%d %H:%M")) + '"\n'
			ss += line
	with open(mainLuaPath, "w", encoding='GB18030') as f:
		f.write(ss)
	# 保存文件
	for v in fileMapping:  # v 文件夹名
		curFileAbsPath = []  # 文件绝对路径
		if fileMapping[v].get('mapper'):
			filePath = os.path.join(projectPath, v)
			# v2 文件名
			for v2 in os.listdir(filePath):
				# 过滤两个特殊文件夹
				if v2.find('.') != -1:
					curFileAbsPath.append(os.path.join(projectPath, v, v2))
			# print('[{}] 文件夹拥有文件'.format(v))
			# print(curFileAbsPath)
		# 读取文件, 写入到git所在文件夹中
		for v in curFileAbsPath:
			if v.rfind('.rc') != -1:
				# print('非文本文件')
				# print(v)
				with open(v, mode='rb') as f:
					content = f.read()
				with open(os.path.join(os.getcwd(), re.search(r"([^\\]+)\.[^.]+$", v).group()), mode='wb') as f:
					f.write(content)
			else:
				# print('文本文件')
				# print(v)
				with open(v, mode='r', encoding='GB18030') as f:
					content = f.read()
				with open(os.path.join(os.getcwd(), re.search(r"([^\\]+)\.[^.]+$", v).group()), mode='w',
						  encoding="UTF-8") as f:
					f.write(content)
	print('更新 or 添加(文件成功)!')
	with open(os.path.join(r'./release', 'script.lr.md5'), mode='r', encoding='UTF-8') as f:
		oldMD5 = f.read()
	with open(packagePath, mode='rb') as f:
		scriptContent = f.read()
		md5.update(scriptContent)
		newMD5 = md5.hexdigest()
	# 判定两次文件是否一致
	if oldMD5 == newMD5:
		print("script.lr的MD5一致")
		sameMD5IsExit = input('是否退出程序[y/n]:') == 'y'
		if sameMD5IsExit:
			exit()
	# 修改文档的最新更新内容 + build 文档
	isChangeDoc = input('是否更新文档[y/n]: ') == 'y'
	inputText = input('输入更新内容: ')
	isFindTarget = False
	if isChangeDoc:
		docPath = os.path.join(os.getcwd(), 'docsResource', 'docs', 'zh', 'guide.md')
		with open(docPath, "r", encoding='UTF-8') as f:
			lines = f.readlines()
			ss = ""
			for line in lines:
				if isFindTarget:
					line = '- ' + inputText + '\n'
					isFindTarget = False
				if re.match('### 最近更新: ', line):
					isFindTarget = True
				ss += line
		with open(docPath, "w", encoding='UTF-8') as f:
			f.write(ss)
		os.system('cd docsResource && npm run build')
		print('文档构建成功!')
		copyDocument()
	# 更新 script.lr 和 script.lr.md5 文件
	with open(os.path.join(r'./release', 'script.lr.md5'), mode='w', encoding='UTF-8') as f:
		f.write(newMD5)
	with open(os.path.join(r'./release', 'script.lr'), mode='wb') as f:
		f.write(scriptContent)
	print('更新脚本文件成功!')
	# 上传脚本文件
	os.system('git add .')
	inputText = '\"{} {}\"'.format(datetime.now().strftime("%Y.%m.%d %H:%M"), inputText)
	os.system('git commit -m {}'.format(inputText))
	os.system('git push')
	print('push 代码文件成功!')
	os.system('cd release && git add . && git commit -m {} && git push'.format(inputText))
	print('push 脚本文件成功!')


# 远程拉去最新代码
def updateLocal():
	os.system('git pull')
	copy()


def copyDocument():
	target = os.getcwd() + '/docs'
	start = os.getcwd() + '/docsResource/docs/.vuepress/dist'
	if os.path.exists(target):
		shutil.rmtree(target)
	shutil.copytree(start, target)
if __name__ == "__main__":
	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("-s", "--stage", help="update source code,copy to jingling,push to git", required=True)
	parser.add_argument("-p", "--project", help="Path to jingling project folder", required=False)
	parser.add_argument("-o", "--out", help="Path to release folder", required=False)
	args = parser.parse_args()
	print(args.stage)
	if args.stage=='1':
		# 复制到懒人精灵
		print('复制代码到精灵项目')
		copy()
	elif  args.stage=='2':
		# pull远程到本地
		updateLocal()
	elif   args.stage=='3':
		# 保存并且上传到git
		saveAndPush()
