import psycopg2
from datetime import datetime

def insert_history_events():
    # 数据库连接配置
    conn_params = {
        'host': '180.101.63.22',
        'port': '52041',
        'database': 'xrrb',
        'user': 'your_username',  # 需要替换为实际用户名
        'password': 'your_password'  # 需要替换为实际密码
    }
    
    try:
        # 连接到数据库
        conn = psycopg2.connect(**conn_params)
        cursor = conn.cursor()
        
        # 获取今天的日期
        today = datetime.now()
        month = today.month
        day = today.day
        
        # 今天的历史事件数据 (科技、政治、文化三个分类)
        events = [
            {
                'title': '1963年首次计算机网络连接实验',
                'description': '美国加州大学洛杉矶分校进行首次计算机间网络连接实验，为ARPANET和现代互联网奠定了基础。',
                'category': '科技',
                'year': 1963,
                'month': 4,
                'day': 10
            },
            {
                'title': '1815年维也纳会议结束',
                'description': '欧洲各国在维也纳会议上签署最终法案，重新划分拿破仑战争后的欧洲政治版图。',
                'category': '政治',
                'year': 1815,
                'month': 4,
                'day': 10
            },
            {
                'title': '1953年DNA双螺旋结构发现公布',
                'description': '沃森和克里克在《自然》杂志发表论文，公布了DNA分子的双螺旋结构模型。',
                'category': '文化',
                'year': 1953,
                'month': 4,
                'day': 10
            }
        ]
        
        # 插入事件到数据库
        insert_query = """
        INSERT INTO history_events (title, description, category, year, month, day, created_at) 
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        
        for event in events:
            cursor.execute(insert_query, (
                event['title'],
                event['description'], 
                event['category'],
                event['year'],
                event['month'],
                event['day'],
                datetime.now()
            ))
        
        # 提交事务
        conn.commit()
        print(f"成功插入 {len(events)} 条历史事件到数据库")
        
    except psycopg2.Error as e:
        print(f"数据库错误: {e}")
    except Exception as e:
        print(f"发生错误: {e}")
    finally:
        if conn:
            cursor.close()
            conn.close()

if __name__ == "__main__":
    insert_history_events()