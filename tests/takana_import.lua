-- Takana 纯数据回归：1/256 拍、变速、层级、曲线、偏好缺省和工程难度选择。
local Converter=require('plugins.takana_import.converter')
local Curves=require('plugins.takana_import.curves')
local Project=require('plugins.takana_import.project')
local Import=require('src.services.importService')
local json=require('src.utils.dkjson')
local function fixture()
    return {properties={version=3,properties={offset={value=135}},editorconfig={layers={value={{id=7}}}}},
        components={{model={type='line'},children={{id=8,name='lane',model={type='track',
            timeStart=0,timeEnd=2000,editorconfig={layer={id=7}},movement={type='trackDirectMovement',
                position={type='position',list={['0']='v1e_(-4.5, s)',['2000']='v1e_(4.5, u)'}},
                width={type='position',list={['0']='v1e_(1.8, u)'}}}},children={
                    {model={type='hit',hitType='Tap',timeJudge=501}},
                    {model={type='hit',hitType='Slide',timeJudge=502,properties={isDummy={value=true}}}},
                    {model={type='hold',timeJudge=999,timeEnd=1000}},
                }}}}}}
end
local function beat(b) return b[1]+b[2]/b[3] end
local function valid(chart)
    assert(Import:validate({chart=chart}))
    for _,list in ipairs({chart.note,chart.event}) do
        for _,item in ipairs(list) do
            for _,b in ipairs({item.beat,item.beat2}) do
                assert(b[3]==256 and b[2]>=0 and b[2]<256)
            end
        end
    end
end
local chart=Converter.convert(fixture())
valid(chart)
assert(chart.bpm_list[1].bpm==120 and chart.offset==-135)
assert(beat(chart.note[1].beat)==257/256 and chart.note[2].fake==1)
assert(chart.note[3].type=='hold' and beat(chart.note[3].beat2)>beat(chart.note[3].beat))
assert(chart.track['1'].name=='lane' and chart.track['1'].zindex==1)
assert(chart.preference.jump_unit=='ms' and chart.preference.jump_mode=='current')
assert(chart.track['1'].start_x==0 and chart.track['1'].start_w==20)
chart=Converter.convert(fixture(),{preference={bpmList={['0']=120,['1000']=240}}})
valid(chart)
assert(#chart.bpm_list==2 and beat(chart.bpm_list[2].beat)==2)
local movement={}
for _,event in ipairs(chart.event) do if event.type=='x' then movement[#movement+1]=event end end
assert(#movement==3 and movement[1].to==50 and movement[2].from==50 and movement[2].to==100)
assert(beat(movement[2].beat2)==6)
local curves={custom_trans={}}
local node=Curves.parse('v1e_(0, 3i)',curves)
assert(math.abs(node.evaluate(0.25)-0.578125)<1e-10, 'Takana In 对应数学 Out')
assert(math.abs(Curves.parse('v1e_(0, 109)',curves).evaluate(0.25)-node.evaluate(0.25))<1e-10)
assert(Curves.parse('v1e_(0, 05)',curves).evaluate(0.25)==Curves.parse('v1e_(0, wb)',curves).evaluate(0.25))
node=Curves.parse('v1b_(0, 0, 2, 1, 2)',curves)
assert(node.trans.type=='custom' and node.evaluate(0.5)>1, '贝塞尔超调必须保留')
assert(math.abs(Curves.parse('v1b_(0, 0, 0, 0, 1)',curves).evaluate(0.000001)-0.000298)<0.00001)
local files={['song.t3proj']='musicFileName: audio.wav\ncoverFileName: art.png\nmasterChartFileName: chart\n',
    ['preference.yaml']='difficulty: 3\nbpmList:\n  0: 180\n',
    ['songinfo.yaml']='title:\n  en: song\ndifficulties:\n  3:\n    levelDisplay: "15"\n',
    ['chart.editing.json']=json.encode(fixture()),['chart.json']='bad JSON',
    ['audio.wav']='music', ['art.png']='cover'}
local function read(name) return files[name] end
local function list() return {'song.t3proj'} end
local project=Project.read(read,list,'song.t3proj',files['song.t3proj'])
assert(project.chart.bpm_list[1].bpm==180 and project.chart.info.chart_name=='chart Lv.15')
assert(project.music=='music' and project.cover=='cover')
files['preference.yaml']=nil
project=Project.read(read,list)
assert(project.chart.bpm_list[1].bpm==120)
assert(Project.yaml('difficulties:\n    3:\n          charter:\n                  en:\n                    maya\n').difficulties['3'].charter.en=='maya')
files['song.t3proj']='musicFileName: ../outside.mp3\nmasterChartFileName: chart\n'
assert(not pcall(Project.read,read,list))
local plugin=require('plugins.takana_import.init')
assert(plugin.review({}, {extension='json',data=json.encode(fixture())}))
assert(not plugin.review({}, {extension='json',data='{"note":[]}'}))
assert(not plugin.review({}, {extension='json',data='invalid'}))
print('PASS: Takana grid, BPM changes, Opposite easings, Bezier overshoot, project selection and defaults')
