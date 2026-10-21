def next_q(q,rst,en):
    if rst: return 0
    if en: return (q+1)&0xf
    return q

def run():
    q=0
    q=next_q(q,1,0); assert q==0
    q=next_q(q,0,1); assert q==1
    q=next_q(q,0,1); assert q==2
    q=next_q(q,0,0); assert q==2
    for _ in range(13):
        q=next_q(q,0,1)
    assert q==15
    q=next_q(q,0,1); assert q==0
    q=next_q(q,1,1); assert q==0
    print("A09 independent Python model: PASS")

if __name__=="__main__":
    run()
