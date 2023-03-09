import os
import datetime

delian_wallet = ["t3q2sc3zvdhcwhuttajyv6zhlfmqfffan736fc552zu5m6vofneecmsbs5b3clrpgexklaqn75fgztim5y6rgq",
                 "t3rjgnxayljutt246waqplqrlb5pyya522arblqa6jvqnbkju54uwjzm64ez5pxovbpf2cjusz5vtb2xqjodca"]
maike_wallet = ["t3xc2fzcfv2ziby2x2zulzle4ju6u54gl36j5ajtkukeqzenlucpvzgu2ml2bh3h4du7nnnq4mbg5mv5tbwffa"]
xingjigonglian_wallet = ["t3rbxwgfu4pdheyppbrtkocsoidicoql4s5jmnpifgkze4pamfv2wth3dt3vjdcwpeb2tyg4ai64d2nzuidxeq",
                         "t3r476pfwu5n7pmv4ms4gswuz4ervrnc2a3up4kp2fiabo6xvv7jaymtleziagar63n7kbad7buvl6odglkf6a",
                         "t3vijl7nakzj5y3rx54hs42ibf3jszicq67jrm6npiq5gnehsnvx6d43rl26jp5uw2d6tkwqwmahuyqlzwfqza"]
yotta_wallet = ["t3wd62gde7j5ciwkxb5ndvfqaedfin542jsewb2rkfzy4yk4t5otb6r6ffnloihwnoudezn4f5ux4quiuj66ta"]
xingjitegong_wallet = ["t3qx6s4beipuu3gcpx5uj2wrypkkzi72lncijmcsygxd2rudwuodqaq3kzs2eqp7uspy2j3r3mtnw45mo65tua",
                       "t3wywy3xbszd2vnknd4zuwv6bpgd2m3qil45jd65b3ecs3a6zr6fgmfrpmthg4diyacwhanchu7h3tfparnhnq"]
self_wallet = ["t3w7u4monbesquves6sjkncw2nyuuqr3qnbgikntg4jxbsscdqojrywwrvtybv5ofdf6mljtspu4sivpkwzeda",
               "t3r2s32yydrod77zu2wtiv7w2ghjt4a6oye333il6y5elmbh6g26tdqw7hragtqptrirmzlriah7qq25uamzza",
               "t3v4vrcabs5d4yztbyb4erza4iuqeltsxo6wukji5kwvnp5rlffcywdg6hewnkvimg74busn3bve7lpyhbkd3a"]
xiongmao_wallet=["t3wi4rl575tvhxswyossd5a3hpr35ini6ek7lf22honhjmij5xjv6vda5orj7qfgut6ysocmhl7nhbskac5noa"]
delian = open("delian", "r")
maike = open("maike", "r")
xingjigonglian = open("xingjigonglian", "r")
yotta = open("yotta", "r")
xingjitegong = open("xingjitegong", "r")
self = open("self", "r")
panda = open("panda", "r")

balance=1

client=["delian","maike","xingjigonglian","yotta","xingjitegong","self"]
for client_list in client:
    c = open(client_list ,"r")

while True:
    try:
        # x = next(fp1).strip()
        # y = next(fp2).strip()
        # 蝶恋
        n = 0
        print("蝶恋")
        for d in delian:
            if len(delian_wallet) > 0:
                for wallet_list in delian_wallet:
                    a = "~/bin/lotus send --from %s %s %s " % (d.replace('\n', ''), delian_wallet[n],balance)
                    print(a)
                    result_d = os.popen(
                        "~/bin/lotus send --from %s %s %s" % (d.replace('\n', ''), delian_wallet[n],balance)).read().rstrip()
                    n += 1
                    if n >= len(delian_wallet):
                        n = 0
                    if result_d.startswith('ba'):
                        print("蝶恋钱到账啦啦啦!!!!:", d.replace('\n', ''), delian_wallet[n],result_d,
                              datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                    break
        # 麦克

        n = 0
        print("麦克")
        for m in maike:
            if len(maike_wallet) >= 0:
                for maike_list in maike_wallet:
                    a = "~/bin/lotus send --from  %s  %s  %s " % (
                        m.replace('\n', ''), maike_wallet[n],balance)
                    print(a)
                    result_m = os.popen(
                        "~/bin/lotus send --from  %s  %s  %s " % (
                            m.replace('\n', ''), maike_wallet[n],balance)).read().rstrip()
                    n += 1
                    if n >= len(maike_wallet):
                        n = 0
                    if result_m.startswith('ba'):
                        print("麦克钱到账啦啦啦!!!!:", m.replace('\n', ''), maike_wallet[n],result_m,
                              datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                    break
        # 星际公链

        n = 0
        print("星际公链")
        for x in xingjigonglian:

            if len(xingjigonglian_wallet) >= 0:
                for wallet_list in delian_wallet:
                    a = "~/bin/lotus send --from  %s  %s  %s " % (
                        x.replace('\n', ''), xingjigonglian_wallet[n],balance)
                    print(a)
                    result_x = os.popen(
                        "~/bin/lotus send --from  %s  %s  %s " % (
                            x.replace('\n', ''), xingjigonglian_wallet[n],balance)).read().rstrip()
                    n += 1
                    if n >= len(xingjigonglian_wallet):
                        n = 0
                    if result_x.startswith('ba'):
                        print("星际公链钱到账啦啦啦!!!!:", x.replace('\n', ''), xingjigonglian_wallet[n],result_x,
                              datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                    break
        # 悠塔

        n = 0
        print("悠塔")
        for y in yotta:

            if len(yotta_wallet) >= 0:
                for wallet_list in yotta_wallet:
                    a = "~/bin/lotus send --from  %s  %s  %s " % (y.replace('\n', ''), yotta_wallet[n],balance)
                    print(a)
                    result_d = os.popen(
                        "~/bin/lotus send --from  %s  %s  %s" % (
                            y.replace('\n', ''), yotta_wallet[n],balance)).read().rstrip()
                    n += 1
                    if n >= len(yotta_wallet):
                        n = 0
                    if result_d.startswith('ba'):
                        print("悠塔钱到账啦啦啦!!!!:", y.replace('\n', ''), yotta_wallet[n],result_d,
                              datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                    break
        # 星际特工
        n = 0
        print("星际特工")
        for tg in xingjitegong:

            if len(xingjitegong_wallet) >= 0:
                for wallet_list in xingjitegong_wallet:
                    a = "~/bin/lotus send --from  %s  %s  %s " % (tg.replace('\n', ''), xingjitegong_wallet[n],balance)
                    print(a)
                    result_d = os.popen(
                        "~/bin/lotus send --from  %s  %s  %s " % (
                            tg.replace('\n', ''), xingjitegong_wallet[n],balance)).read().rstrip()
                    n += 1
                    if n >= len(xingjitegong_wallet):
                        n = 0
                    if result_d.startswith('ba'):
                        print("星际特工钱到账啦啦啦!!!!:", tg.replace('\n', ''), xingjitegong_wallet[n],result_d,
                              datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                    break
        # 我们自己

        n = 0
        print("我们自己")
        for my in self:

            if len(self_wallet) >= 0:
                for wallet_list in self_wallet:
                    a = "~/bin/lotus send --from  %s  %s  %s " % (my.replace('\n', ''), self_wallet[n],balance)
                    print(a)
                    result_d = os.popen(
                        "~/bin/lotus send --from  %s  %s  %s " % (
                            my.replace('\n', ''), self_wallet[n],balance)).read().rstrip()
                    n += 1
                    if n >= len(self_wallet):
                        n = 0
                    if result_d.startswith('ba'):
                        print("我们自己的钱到账啦啦啦!!!!:", my.replace('\n', ''), self_wallet[n],result_d,
                              datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                    break
        n = 0
        print("熊猫的")
        for p in panda:
            if len(xiongmao_wallet) >= 0:
                for wallet_list in xiongmao_wallet:
                    a = "~/bin/lotus send --from  %s  %s  %s " % (p.replace('\n', ''), xiongmao_wallet[n],balance)
                    print(a)
                    result_d = os.popen(
                        "~/bin/lotus send --from  %s  %s  %s " % (
                            p.replace('\n', ''), xiongmao_wallet[n],balance)).read().rstrip()
                    n += 1
                    if n >= len(xiongmao_wallet):
                        n = 0
                    if result_d.startswith('ba'):
                        print("我们自己的钱到账啦啦啦!!!!:", p.replace('\n', ''), xiongmao_wallet[n],result_d,
                              datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
                    break
        break
    except StopIteration:
        break
