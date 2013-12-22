

class Space
    constructor: (@container) ->
        @last_time = null
        @objects = []

        @scene = new THREE.Scene
        @renderer = new THREE.WebGLRenderer
        @renderer.setSize(@container.offsetWidth, @container.offsetHeight)
        #@renderer.setClearColor 0x0099FF, 1
        @container.appendChild( @renderer.domElement )
        
        @camera = new THREE.PerspectiveCamera(45, @container.offsetWidth / @container.offsetHeight, 1, 4000 )
        @camera.position.set  0, 0, 10
        
        @addLight  0,  0,  1, 0xffffff, 1.5
        @addLight  0,  0, -1, 0xFFFF99, 1.5
        @addLight  1,  0,  0, 0xFF66CC, 1.5
        @addLight -1,  0,  0, 0x00FF33, 1.5
        @addLight  0,  1,  0, 0x0033FF, 1.5
        @addLight  0, -1,  0, 0xFF3300, 1.5
        
        window.addEventListener 'resize', => @onWindowResize()
        @container.addEventListener 'click', (evt) => @toggleFullScreen(evt)
        @start_stats()


    addLight: (x, y, z, color, intensity) ->
        light = new THREE.DirectionalLight color, intensity
        light.position.set x, y, z
        @scene.add light


    isFullscreen: ->
        document.webkitIsFullScreen || document.mozFullScreen


    toggleFullScreen: (et) ->
        el = et.target
        if not @isFullscreen()
            if el.requestFullscreen
                el.requestFullscreen()
            else if el.mozRequestFullScreen
                el.mozRequestFullScreen()
            else if el.webkitRequestFullscreen
                el.webkitRequestFullscreen Element.ALLOW_KEYBOARD_INPUT
        else
            if document.cancelFullScreen
                document.cancelFullScreen()
            else if document.mozCancelFullScreen
                document.mozCancelFullScreen()
            else if document.webkitCancelFullScreen
                document.webkitCancelFullScreen()


    onWindowResize: ->
        if @isFullscreen
            w = window.innerWidth
            h = window.innerHeight
        else
            w = @container.offsetWidth
            h = @container.offsetHeight
        @camera.aspect = w / h
        @camera.updateProjectionMatrix()
        @renderer.setSize(w, h)


    start_stats: ->
        @stats = new Stats
        #@stats.setMode(1) // 0: fps, 1: ms
        @stats.domElement.style.position = 'absolute'
        @stats.domElement.style.left = '0px'
        @stats.domElement.style.top = '0px'
        document.body.appendChild @stats.domElement


    update: (t_step, timestamp) ->
        t = new Date().getTime()
        @camera.position.x = 0 + Math.sin(t * 0.0002 + Math.PI / 2) * 10
        @camera.position.z = 0 + Math.sin(t * 0.0002) * 10
        @camera.position.y = 5
        @camera.lookAt(new THREE.Vector3(0,0,0))
        for o in @objects
            o.update(t_step, timestamp)


    run: (timestamp) ->
        timestamp = 0 unless timestamp
        @last_time = timestamp unless @last_time
        t_step = timestamp - @last_time
        @update(t_step, timestamp)
        @render()
        @last_time = timestamp
        @stats.update()
        requestAnimationFrame (par) => @run par


    add: (obj) ->
        @scene.add obj.object3D 
        obj.attachScene @
        @objects.push obj

    render: ->
        @renderer.render @scene, @camera


class Object3D
    attachScene: (scene) ->
        @scene = scene


    update: (t_step, timestamp) ->
        t_step


    setObject3D: (m) ->
        @object3D = m


    setPosition: (pos) ->
        @setPos = pos
        @object3D.position.x = pos[0]
        @object3D.position.y = pos[1]
        @object3D.position.z = pos[2]
        @


class Cube extends Object3D
    constructor: ->
        materials = @makeMaterials()
        material = new THREE.MeshFaceMaterial( materials )
        geometry = new THREE.CubeGeometry(1, 1, 1)
        mesh = new THREE.Mesh(geometry, material)
        @setObject3D mesh


    makeMaterials: ->
        for i in [0..5]
            new THREE.MeshPhongMaterial map: THREE.ImageUtils.loadTexture("img/Numbers-#{i}-icon.png")


    update: (t_step, timestamp) ->


class CubeSpin extends Cube
    allowedRotations: (rot) ->
        [@rotX, @rotY, @rotZ] = rot
        @rotXspeed = 0.01
        @rotYspeed = 0.01
        @rotZspeed = 0.01
        @

    update: (t_step, timestamp) ->
        step = t_step / 16.7
        if @rotX
            @object3D.rotation.x -= step * @rotXspeed
        if @rotY
            @object3D.rotation.y -= step * @rotYspeed
        if @rotZ
            @object3D.rotation.z -= step * @rotZspeed
        super t_step, timestamp


class CubeRot extends CubeSpin
    constructor: ->
        @rotStart = Math.PI * Math.random()
        super


    update: (t_step, timestamp) ->
        t = new Date().getTime()
        if @rotY
            @object3D.position.x = @setPos[0] + Math.sin(t * 0.0015 + @rotStart)
        if @rotX
            @object3D.position.y = @setPos[1] + Math.sin(t * 0.0015 + @rotStart)
        if @rotZ
            @object3D.position.z = @setPos[2] + Math.sin(t * 0.0015 + @rotStart)
        super t_step, timestamp



makeGrid = (spacX = 1, spacY = 1, spacZ = 1, countX = 1, countY = 1, countZ = 1, center = true) ->
    result = []
    centerX = if center then spacX * (countX - 1) / 2 else 0
    centerY = if center then spacY * (countY - 1) / 2 else 0
    centerZ = if center then spacZ * (countZ - 1) / 2 else 0
    for x in [0...countX]
        for y in [0...countY]
            for z in [0...countZ]
                result.push [x * spacX - centerX, y * spacY - centerY, z * spacZ - centerZ]
    result


makeCombinations = (size) ->
    for x in [0...Math.pow(2, size)]
        s = x.toString(2)
        zeros = new Array(size - s.length + 1).join('0')
        i is '1' for i in (zeros + s)


printout = (o) ->
    console.log JSON.stringify o


run_cubes = (container) ->
    m = new Space container
    grid = makeGrid spacX = 3, spacY = 3, spacZ = 0, countX = 4, countY = 2
    rotations = makeCombinations 3
    for [gpos, rpos] in _.zip grid, rotations
        c = new CubeRot().setPosition(gpos).allowedRotations(rpos)
        m.add c
    m.run() 


window.LL = window.LL || {}
window.LL.run_cubes = run_cubes

#window.onload = -> run_cubes document.getElementById "container"
        