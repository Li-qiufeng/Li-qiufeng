#!/usr/bin/env python
#coding:utf-8
###################################################################
#Auth:Zhuzhengjun
#LastModified:2015/01/14
#Version 1.0
#Function Description:
#Batch automatically generated/delete VM
#1.Generated VM
##1.1.Create qcow2 vm img file
##1.2.Create VM XML file
###1.2.1.Update UUID
###1.2.2.Update MAC
###1.2.3.Update img path
###1.2.4.Update VM Name
#2.Edit VM
##2.1.Edit HostName
##2.2.Edit Mac
##2.3.Edit IP
#3.Start VM
#4.Delete VM
####################################################################
 
#import module
import shutil
import os,sys
from virtinst.util import *
import libvirt
import re
import subprocess
import guestfs
import jinja2
 
if sys.version_info < (2,5):
        import lxml.etree as ET
else:
        import xml.etree.ElementTree as ET
 
#Define variables
 
template_img_path="/template/img"
template_xml_path="/template/xml"
vm_img_path="/var/lib/libvirt/images"
vm_xml_path="/etc/libvirt/qemu"
vm_file="/template/scripts/vm.ini"
uri="qemu:///system"
domain=".tc.com"
 
JINJA = jinja2.Environment(
    loader=jinja2.FileSystemLoader(
        '/template/jinja'
    )
)
 
def file_exists(file):
    if os.path.exists(file):
        return 1
    else:
        return 0
 
def create_vm_img_file(src_img_file,dst_img_file):
    command="/usr/bin/qemu-img create -f qcow2 -o cluster_size=2M,backing_file="+src_img_file+" "+dst_img_file+" 20G"
    try:
        subprocess.check_call(command,shell=True)
    except subprocess.CalledProcessError as err:
        print "Error:",err
        sys.exit(1)
    print "Done!"
 
'''
def copy_vm_img_file(src_img_file,dst_img_file):
    print "Start Copy",src_img_file,"to",dst_img_file
    if file_exists(dst_img_file):
        print "File %s exists, abort" % dst_img_file
        sys.exit(1)
    shutil.copyfile(src_img_file,dst_img_file)
    print "Done!"
'''
 
def start_vm(vm_xml_file,vm_name):
    try:
        conn = libvirt.open(uri)
    except Exception,e:
        print 'Faild to open connection to the hypervisor'
        sys.exit(1)
    create = True
    if create:
        xmlfile=open(vm_xml_file)
        xmldesc=xmlfile.read()
        xmlfile.close()
    try:
        vmname = conn.defineXML(xmldesc)
    except Exception,e:
        print "Failed to define %s:%s" %(vm_name,e)
        sys.exit(1)
    if vmname is None:
        print 'whoops this shouldnt happen!'
    try:
        vmname.create()
    except Exception,e:
        print "Failed to create %s:%s" %(vm_name,e)
        sys.exit(1)
    try:
        print "Domain 0:id %d running %s" %(vmname.ID(),vmname.name())
    except Exception,e:
        print e
    try:
        conn.close()
    except:
        print "Faild to close the connection!"
        sys.exit(1)
    print "Done!"
    print "="*100
 
def edit_vm(dst_img_file,vm_mac,vm_ip,hostname):
    g = guestfs.GuestFS(python_return_dict=True)
    g.add_drive_opts(dst_img_file)
    g.launch()
    partions_root=g.inspect_os()
    g.mount(partions_root[0],'/')
 
    #edit hostname
    hostname_fn='hostname.jinja'
    try:
        template_hostname = JINJA.get_template(hostname_fn)
    except jinja2.exceptions.TemplateNotFound:
        print "error"
        sys.exit(1)
    hostname_context={'hostname':hostname}
    hostname_content=template_hostname.render(**hostname_context)
    g.write('/etc/sysconfig/network',hostname_content)
 
    #edit mac
    mac_fn='mac.jinja'
    try:
        template_mac = JINJA.get_template(mac_fn)
    except jinja2.exceptions.TemplateNotFound:
        print "error"
        sys.exit(1)
    mac_context={'mac':vm_mac}
    mac_content=template_mac.render(**mac_context)
    g.write('/etc/udev/rules.d/70-persistent-net.rules',mac_content)
 
    #edit ip
    net_fn='net.jinja'
    try:
        template_net = JINJA.get_template(net_fn)
    except jinja2.exceptions.TemplateNotFound:
        print "error"
        sys.exit(1)
    net_context={'mac':vm_mac,'ip':vm_ip}
    net_content=template_net.render(**net_context)
    g.write('/etc/sysconfig/network-scripts/ifcfg-eth0',net_content)
    g.close()
 
def create_vm_xml_file(src_xml_file,vm_name,dst_img_file,vm_ip,hostname):
    config = ET.parse(src_xml_file)
    name = config.find('name')
    name.text = vm_name.strip()
    uuid = config.find('uuid')
    uuid.text = uuidToString(randomUUID())
    mac = config.find('devices/interface/mac')
    vm_mac=randomMAC(type='qemu')
    mac.attrib['address'] = vm_mac
    disk = config.find('devices/disk/source')
    disk.attrib['file']=dst_img_file
    vm_xml_name=vm_name.strip() + '.xml'
    vm_xml_file=os.path.join(vm_xml_path,vm_xml_name)
    if file_exists(vm_xml_file):
        print "File %s exists, abort" % vm_xml_file
        sys.exit(1)
    config.write(vm_xml_file)
    print "Created vm config file %s" % vm_xml_file
    #print "Use disk image %s, you must create it from the template disk: %s" % (disk_image, disk_old)
    print "Done!"
    #Function 2 Edit VM
    edit_vm(dst_img_file,vm_mac,vm_ip,hostname)
 
    #Function 3 Start VM
    print "Start VM "+hostname
    start_vm(vm_xml_file,vm_name)
def delete_file(file_name):
    if file_exists(file_name):
        os.unlink(file_name)
def delete_vm(vm_name):
    vmimg=vm_name+".qcow2"
    vmxml=vm_name+".xml"
    img_file=os.path.join(vm_img_path,vmimg)
    xml_file=os.path.join(vm_xml_path,vmxml)
    try:
        conn = libvirt.open(uri)
    except Exception,e:
        print 'Faild to open connection to the hypervisor'
        sys.exit(1)
    try:
        server=conn.lookupByName(vm_name)
    except Exception,e:
        print e
        sys.exit(1)
    if server.isActive():
        print "VM %s will be shutdown!" %vm_name
        try:
            #server.shutdown()#VM need install acpid
            server.destroy()
        except Exception,e:
            print e
            sys.exit(1)
        print "VM %s will be delete!" %vm_name
        try:
            server.undefine()
        except Exception,e:
            print e
            sys.exit(1)
                                 
        delete_file(img_file)
        delete_file(xml_file)
                                       
        try:
            conn.close()
        except:
            print "Faild to close the connection!"
            sys.exit(1)
    else:
        print "VM %s will be delete!" %vm_name
        try:
            server.undefine()
        except Exception,e:
            print e
            sys.exit(1)
                                        
        delete_file(img_file)
        delete_file(xml_file)
    print "Done"
    print "="*100
 
###############Main############################################
#Open config file
fh=open(vm_file)
vm_config=fh.readlines()
fh.close()
for line in vm_config:
    passline=re.compile("#.*")
    if re.search(passline,line)!=None:
        continue
    (action,vm_name,src_file,xml_file,vm_ip)=line.strip().split(",")
    hostname=vm_name+domain
    if action=='add':
        src_img_file=os.path.join(template_img_path,src_file)
        dst_img_file=os.path.join(vm_img_path,vm_name.strip()+".qcow2")
        src_xml_file=os.path.join(template_xml_path,xml_file)
        if not (file_exists(src_img_file) and file_exists(src_xml_file)):
            print "File %s or %s not exists,abort!" %(src_img_file,src_xml_file)
            sys.exit(1)
                                
        #Function1.1 Create qcow2 vm img file
        print "Create VM "+hostname+" image file and file type qcow2"
        create_vm_img_file(src_img_file,dst_img_file)
        #Function1.2 Create VM XML file
        print "Create VM "+hostname+"  Xml config file"
        create_vm_xml_file(src_xml_file,vm_name,dst_img_file,vm_ip,hostname)
    elif action=="delete":
        #Function4 Delete VM
        print "Delete VM"
        delete_vm(vm_name)
